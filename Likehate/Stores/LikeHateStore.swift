import Foundation
import SwiftUI
import UIKit

/// 人物、好き嫌い、設定、課金状態をまとめて管理するアプリの中心ストア。
@MainActor
final class LikeHateStore: ObservableObject {
   private enum Constants {
      static let launchReviewRequestCountKey = "LaunchReviewRequestCount"
      static let registrationReviewRequestCountKey = "RegistrationReviewRequestCount"
      static let personsKey = "LikehatePersonsV1"
      static let itemsKey = "LikehateItemsV1"
      static let dataMigrationVersionKey = "LikehateDataMigrationVersion"
      static let currentDataMigrationVersion = 1
      static let animationEnabledKey = "AnimationEnabled"
      static let hapticsEnabledKey = "HapticsEnabled"
      static let adRemovedKey = "BuyRemoveAd"
      static let premiumPurchasedKey = "PremiumLifetimePurchased"
      static let textSizeKey = "AppTextSize"
      static let personPhotosDirectoryName = "PersonPhotos"
      static let personPhotoSize = CGSize(width: 512, height: 512)
   }

   /// 登録されている人物一覧。
   @Published private(set) var persons: [Person]
   /// すべての人物に紐づく好き嫌いの記録。
   @Published private(set) var entries: [LikeDislikeItem]
   /// 旧広告非表示購入を含む広告非表示フラグ。
   @Published var didBuyRemoveAd: Bool
   /// 買い切りプレミアムが有効かどうか。
   @Published var didBuyPremium: Bool
   /// Lottieなどの装飾アニメーションを再生するかどうか。
   @Published var animationEnabled: Bool {
      didSet {
         defaults.set(animationEnabled, forKey: Constants.animationEnabledKey)
      }
   }
   /// アプリ独自の文字サイズ設定。
   @Published var textSize: AppTextSize {
      didSet {
         defaults.set(textSize.rawValue, forKey: Constants.textSizeKey)
      }
   }
   /// 購入や復元の結果として表示する一時メッセージ。
   @Published var purchaseMessage: PurchaseMessage?
   /// レビュー依頼の表示状態。
   @Published var reviewPrompt: ReviewPrompt?
   /// プレミアム購入処理中かどうか。
   @Published var isPurchasing = false
   /// 購入復元処理中かどうか。
   @Published var isRestoring = false
   /// RevenueCatから取得したプレミアム商品の表示価格。
   @Published var premiumProductPrice: String?

   let defaults: UserDefaults
   private let premiumPurchaseService: PremiumPurchaseServicing
   private var premiumPackage: PremiumPackage?
   private var premiumEntitlementObserver: NSObjectProtocol?

   /// 保存済みデータを読み込み、必要な移行と課金状態の互換処理を行う。
   init(defaults: UserDefaults = .standard, premiumPurchaseService: PremiumPurchaseServicing = RevenueCatPremiumPurchaseService()) {
      self.defaults = defaults
      self.premiumPurchaseService = premiumPurchaseService
      let storedAdsRemoved = defaults.bool(forKey: Constants.adRemovedKey)
      let storedPremium = defaults.bool(forKey: Constants.premiumPurchasedKey)
      let hasStoredPremiumAccess = storedPremium || storedAdsRemoved
      self.didBuyRemoveAd = storedAdsRemoved
      self.didBuyPremium = hasStoredPremiumAccess
      self.animationEnabled = defaults.object(forKey: Constants.animationEnabledKey) as? Bool ?? true
      self.textSize = AppTextSize(rawValue: defaults.string(forKey: Constants.textSizeKey) ?? "") ?? .standard

      if storedAdsRemoved {
         defaults.set(true, forKey: Constants.premiumPurchasedKey)
      }

      let now = Date()
      if let loadedPersons: [Person] = Self.decode([Person].self, forKey: Constants.personsKey, defaults: defaults) {
         let normalizedPersons = Self.normalizedPersons(loadedPersons, now: now)
         let validPersonIDs = Set(normalizedPersons.map(\.id))
         let loadedEntries: [LikeDislikeItem] = Self.decode([LikeDislikeItem].self, forKey: Constants.itemsKey, defaults: defaults) ?? []
         self.persons = normalizedPersons
         self.entries = loadedEntries.filter { validPersonIDs.contains($0.personId) }
      } else {
         let migrated = Self.migratedLegacyData(defaults: defaults, now: now)
         self.persons = migrated.persons
         self.entries = migrated.entries
      }

      persistPeopleAndEntries()
      observePremiumEntitlementUpdates()
   }

   /// `isMe` の人物。初回起動時や移行後は必ず1人存在する想定。
   var mePerson: Person? {
      persons.first(where: \.isMe)
   }

   /// わたしに紐づく好きなもののタイトル一覧。
   var likes: [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: .like).map(\.title)
   }

   /// わたしに紐づく嫌いなもののタイトル一覧。
   var hates: [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: .hate).map(\.title)
   }

   /// アプリ内に保存されている好き嫌い記録の合計件数。
   var totalItemCount: Int {
      entries.count
   }

   /// 画面側へ渡す現在の設定値。
   var appSettings: AppSettings {
      AppSettings(
         animationEnabled: animationEnabled,
         vibrationEnabled: defaults.object(forKey: Constants.hapticsEnabledKey) as? Bool ?? true,
         adsRemoved: didBuyRemoveAd,
         isPremium: didBuyPremium,
         textSize: textSize
      )
   }

   /// 人数制限や広告表示の判定に使うプレミアム状態。
   var premiumAccessPolicy: PremiumAccessPolicy {
      PremiumAccessPolicy(
         isPremium: didBuyPremium,
         adsRemoved: didBuyRemoveAd,
         personCount: persons.count
      )
   }

   /// 買い切りプレミアム、または旧広告非表示購入が有効かどうか。
   var hasPremiumAccess: Bool {
      premiumAccessPolicy.hasPremiumAccess
   }

   /// 現在の購入状態と人数で新しい人物を追加できるかどうか。
   var canAddPerson: Bool {
      premiumAccessPolicy.canAddPerson
   }

   /// 設定文字サイズとDynamic Typeを反映したタイポグラフィ。
   func typography(for dynamicTypeSize: DynamicTypeSize) -> AppTypography {
      AppTypography(textSize: textSize, dynamicTypeSize: dynamicTypeSize)
   }

   /// 設定文字サイズに応じた余白や行高。
   var layoutMetrics: AppLayoutMetrics {
      AppLayoutMetrics(textSize: textSize)
   }

   /// 新規追加時に既存人物とできるだけ被らないプリセット画像を返す。
   func defaultProfileImageForNewPerson() -> DefaultProfileImage {
      let usedImages = Set(persons.map(\.profileImage))
      return DefaultProfileImage.firstAvailable(excluding: usedImages)
   }

   /// デバッグ用データ差し替えなどで人物と記録をまとめて置き換える。
   func replacePeopleAndEntries(persons newPersons: [Person], entries newEntries: [LikeDislikeItem]) {
      persons = newPersons
      entries = newEntries
   }

   /// IDに一致する人物を返す。
   func person(for id: UUID) -> Person? {
      persons.first { $0.id == id }
   }

   /// わたしに紐づく指定種別のタイトル一覧。
   func items(for kind: EntryKind) -> [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: kind).map(\.title)
   }

   /// 指定人物と種別に紐づく記録を並び順つきで返す。
   func items(for personID: UUID, kind: EntryKind) -> [LikeDislikeItem] {
      entries
         .filter { $0.personId == personID && $0.type == kind }
         .sorted {
            if $0.sortOrder == $1.sortOrder {
               return $0.createdAt < $1.createdAt
            }
            return $0.sortOrder < $1.sortOrder
         }
   }

   /// 人物に設定された写真ファイルのURLを返す。
   func photoURL(for person: Person) -> URL? {
      guard let photoFileName = person.photoFileName else { return nil }
      guard let url = Self.photoURL(fileName: photoFileName) else { return nil }
      return FileManager.default.fileExists(atPath: url.path) ? url : nil
   }

   /// 人物に設定された写真画像を読み込む。
   func photoImage(for person: Person) -> UIImage? {
      guard let photoURL = photoURL(for: person) else { return nil }
      return UIImage(contentsOfFile: photoURL.path)
   }

   /// 新しい人物を追加し、写真があればアプリ内領域へ保存する。
   func addPerson(
      named rawName: String,
      profileImage: DefaultProfileImage = .random(),
      profileImageSource: FAProfileImageSource = .randomPreset,
      photoData: Data? = nil
   ) -> Person? {
      let name = sanitizedPersonName(rawName)
      guard !name.isEmpty, canAddPerson else { return nil }

      let now = Date()
      let personID = UUID()
      let photoFileName = photoData.flatMap { Self.savePhotoData($0, personID: personID) }
      let resolvedProfileImageSource = photoData == nil ? profileImageSource : FAProfileImageSource.selectedPhoto
      let person = Person(
         id: personID,
         name: name,
         profileImageName: profileImage.rawValue,
         photoFileName: photoFileName,
         isMe: false,
         createdAt: now,
         updatedAt: now,
         sortOrder: nextPersonSortOrder()
      )
      persons.append(person)
      persistPersons()

      FAAnalytics.log(.track(.personAdded, parameters: personAnalyticsParameters(person, source: "add", profileImageSource: resolvedProfileImageSource)))
      HapticsClient.success()
      return person
   }

   /// 既存人物の呼び方、プリセット、写真を更新する。
   func updatePerson(
      _ personID: UUID,
      name rawName: String,
      profileImage: DefaultProfileImage? = nil,
      profileImageSource: FAProfileImageSource? = nil,
      photoData: Data? = nil,
      removesPhoto: Bool = false
   ) {
      let name = sanitizedPersonName(rawName)
      guard !name.isEmpty, let index = persons.firstIndex(where: { $0.id == personID }) else { return }

      let resolvedProfileImageSource = profileImageSource ?? resolvedProfileImageSourceForUpdate(
         person: persons[index],
         profileImage: profileImage,
         photoData: photoData,
         removesPhoto: removesPhoto
      )
      persons[index].name = name
      if let profileImage {
         persons[index].profileImageName = profileImage.rawValue
      }
      if removesPhoto {
         Self.deletePhotoFile(named: persons[index].photoFileName)
         persons[index].photoFileName = nil
      }
      if let photoData, let photoFileName = Self.savePhotoData(photoData, personID: personID) {
         persons[index].photoFileName = photoFileName
      }
      persons[index].updatedAt = Date()
      persistPersons()

      FAAnalytics.log(.track(.personUpdated, parameters: personAnalyticsParameters(persons[index], source: "edit", profileImageSource: resolvedProfileImageSource)))
      HapticsClient.success()
   }

   /// 人物とその人物に紐づく記録・写真を削除する。わたしは削除しない。
   func deletePerson(_ personID: UUID) {
      guard let index = persons.firstIndex(where: { $0.id == personID }), !persons[index].isMe else { return }

      let person = persons[index]
      let deletedItemCount = entries.filter { $0.personId == personID }.count
      Self.deletePhotoFile(named: person.photoFileName)
      persons.remove(at: index)
      entries.removeAll { $0.personId == personID }
      normalizeSortOrders()
      persistPeopleAndEntries()

      var parameters = personAnalyticsParameters(person, source: "delete")
      parameters[.deletedItemCount] = deletedItemCount
      FAAnalytics.log(.track(.personDeleted, parameters: parameters))
      HapticsClient.success()
   }

   /// わたしに好き嫌いの記録を追加する。
   func add(_ text: String, to kind: EntryKind) {
      guard let mePerson else { return }
      add(text, to: kind, personID: mePerson.id)
   }

   /// 指定人物に好き嫌いの記録を追加する。
   func add(_ text: String, to kind: EntryKind, personID: UUID) {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty, let person = person(for: personID) else { return }

      let now = Date()
      let item = LikeDislikeItem(
         id: UUID(),
         personId: personID,
         type: kind,
         title: trimmed,
         note: nil,
         createdAt: now,
         updatedAt: now,
         sortOrder: nextItemSortOrder(personID: personID, kind: kind)
      )
      entries.append(item)
      persistEntries()

      FAAnalytics.log(.track(.entrySaved, parameters: analyticsParameters(for: kind, person: person, textLength: trimmed.count, entryText: trimmed)))
      HapticsClient.success()
      recordRegistrationAndRequestReviewIfNeeded()
   }

   /// 記録のタイトルを編集する。
   @discardableResult
   func updateItem(_ itemID: UUID, title rawTitle: String) -> Bool {
      let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !title.isEmpty, let index = entries.firstIndex(where: { $0.id == itemID }) else { return false }

      entries[index].title = title
      entries[index].updatedAt = Date()
      persistEntries()

      FAAnalytics.log(.track(.entryUpdated, parameters: analyticsParameters(for: entries[index].type, personID: entries[index].personId, textLength: title.count, entryText: title)))
      HapticsClient.success()
      return true
   }

   /// 起動回数を記録し、条件に達した場合だけレビュー依頼を出す。
   func recordLaunchAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.launchReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.launchReviewRequestCountKey)

      FAAnalytics.log(.track(.appLaunchCountRecorded, parameters: [
         .launchCount: nextCount,
         .likeCount: likes.count,
         .hateCount: hates.count,
         .entryCount: entries.count,
         .personCount: persons.count,
         .didBuyRemoveAd: didBuyRemoveAd
      ]))
      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByLaunchCount")
   }

   /// わたしの指定種別の記録を削除する。
   func delete(at offsets: IndexSet, from kind: EntryKind) {
      guard let mePerson else { return }
      delete(at: offsets, from: kind, personID: mePerson.id)
   }

   /// 指定人物の指定種別の記録を削除する。
   func delete(at offsets: IndexSet, from kind: EntryKind, personID: UUID) {
      let orderedItems = items(for: personID, kind: kind)
      let deletedIDs = offsets.compactMap { offset in
         orderedItems.indices.contains(offset) ? orderedItems[offset].id : nil
      }
      guard !deletedIDs.isEmpty else { return }

      entries.removeAll { deletedIDs.contains($0.id) }
      renumberItems(personID: personID, kind: kind)
      persistEntries()

      FAAnalytics.log(.track(.entryDeleted, parameters: analyticsParameters(for: kind, personID: personID).merging([
         .deletedCount: deletedIDs.count
      ])))
   }

   /// わたしの指定種別の記録を並び替える。
   func move(from source: IndexSet, to destination: Int, in kind: EntryKind) {
      guard let mePerson else { return }
      move(from: source, to: destination, in: kind, personID: mePerson.id)
   }

   /// 指定人物の指定種別の記録を並び替える。
   func move(from source: IndexSet, to destination: Int, in kind: EntryKind, personID: UUID) {
      var orderedItems = items(for: personID, kind: kind)
      orderedItems.move(fromOffsets: source, toOffset: destination)

      for (sortOrder, item) in orderedItems.enumerated() {
         guard let index = entries.firstIndex(where: { $0.id == item.id }) else { continue }
         entries[index].sortOrder = sortOrder
         entries[index].updatedAt = Date()
      }
      persistEntries()

      FAAnalytics.log(.track(.entryReordered, parameters: analyticsParameters(for: kind, personID: personID).merging([
         .movedCount: source.count,
         .destination: destination
      ])))
   }

   /// すべての人物と記録を初期状態に戻す。
   func deleteAll() {
      let likeCount = entries.filter { $0.type == .like }.count
      let hateCount = entries.filter { $0.type == .hate }.count
      let personCount = persons.count
      let me = Self.makeMePerson(now: Date(), sortOrder: 0)

      Self.deleteAllPhotoFiles()
      persons = [me]
      entries = []
      defaults.removeObject(forKey: EntryKind.like.storageKey)
      defaults.removeObject(forKey: EntryKind.hate.storageKey)
      persistPeopleAndEntries()

      FAAnalytics.log(.track(.allEntriesDeleted, parameters: [
         .likeCount: likeCount,
         .hateCount: hateCount,
         .totalCount: likeCount + hateCount,
         .personCount: personCount
      ]))
   }

   /// 2人の好き嫌いを比較し、カテゴリごとのタイトル一覧を作る。
   func comparisonSections(firstPersonID: UUID, secondPersonID: UUID) -> [ComparisonSection] {
      let firstLikes = uniqueComparisonTitles(from: items(for: firstPersonID, kind: .like))
      let secondLikes = uniqueComparisonTitles(from: items(for: secondPersonID, kind: .like))
      let firstHates = uniqueComparisonTitles(from: items(for: firstPersonID, kind: .hate))
      let secondHates = uniqueComparisonTitles(from: items(for: secondPersonID, kind: .hate))

      let firstLikeKeys = Set(firstLikes.map(\.key))
      let secondLikeKeys = Set(secondLikes.map(\.key))
      let firstHateKeys = Set(firstHates.map(\.key))
      let secondHateKeys = Set(secondHates.map(\.key))

      return [
         ComparisonSection(category: .commonLike, titles: firstLikes.filter { secondLikeKeys.contains($0.key) }.map(\.title)),
         ComparisonSection(category: .commonHate, titles: firstHates.filter { secondHateKeys.contains($0.key) }.map(\.title)),
         ComparisonSection(category: .firstOnlyLike, titles: firstLikes.filter { !secondLikeKeys.contains($0.key) }.map(\.title)),
         ComparisonSection(category: .secondOnlyLike, titles: secondLikes.filter { !firstLikeKeys.contains($0.key) }.map(\.title)),
         ComparisonSection(category: .firstOnlyHate, titles: firstHates.filter { !secondHateKeys.contains($0.key) }.map(\.title)),
         ComparisonSection(category: .secondOnlyHate, titles: secondHates.filter { !firstHateKeys.contains($0.key) }.map(\.title))
      ]
   }

   /// プレミアム商品の価格やパッケージ情報を読み込む。
   func loadPremiumProductInfo() {
      guard premiumProductPrice == nil, premiumPackage == nil else { return }

      Task {
         do {
            FAAnalytics.log(.track(.premiumProductFetchStarted, parameters: premiumAnalyticsParameters(source: "load")))
            _ = try await fetchPremiumPackage()
         } catch {
            FAAnalytics.log(.track(.premiumProductFetchFailed, parameters: premiumAnalyticsParameters(source: "load").merging([
               .errorDescription: error.localizedDescription
            ])))
         }
      }
   }

   /// RevenueCat経由で買い切りプレミアムを購入する。
   func purchasePremium() {
      guard !isPurchasing, !hasPremiumAccess else { return }
      isPurchasing = true
      FAAnalytics.log(.track(.premiumPurchaseStarted, parameters: premiumAnalyticsParameters(source: "purchase")))

      Task {
         await purchasePremiumPackage()
      }
   }

   /// RevenueCat経由で購入状態を復元する。
   func restorePurchases() {
      guard !isRestoring else { return }
      isRestoring = true
      FAAnalytics.log(.track(.premiumRestoreStarted, parameters: premiumAnalyticsParameters(source: "restore")))

      Task {
         await restorePremiumPurchases()
      }
   }

   /// 起動時や復帰時にRevenueCatの権利状態を再確認する。
   func refreshPremiumStatus() {
      Task {
         do {
            let entitlementState = try await premiumPurchaseService.currentEntitlementState()
            applyPremiumEntitlement(isActive: entitlementState.isActive)
            FAAnalytics.log(.track(.premiumStatusRefreshed, parameters: [
               .isPremium: hasPremiumAccess
            ]))
         } catch {
            FAAnalytics.log(.track(.premiumStatusRefreshFailed, parameters: [
               .errorDescription: error.localizedDescription
            ]))
         }
      }
   }

   private func fetchPremiumPackage() async throws -> PremiumPackage? {
      let package = try await premiumPurchaseService.currentPremiumPackage()
      premiumPackage = package
      premiumProductPrice = package?.localizedPrice
      if let package {
         FAAnalytics.log(.track(.premiumProductFetchSucceeded, parameters: premiumAnalyticsParameters(source: "fetch").merging([
            .price: package.localizedPrice,
            .productID: LikehateRevenueCatContracts.premiumProductID
         ])))
      } else {
         FAAnalytics.log(.track(.premiumProductFetchUnavailable, parameters: premiumAnalyticsParameters(source: "fetch").merging([
            .productID: LikehateRevenueCatContracts.premiumProductID
         ])))
      }
      return package
   }

   private func purchasePremiumPackage() async {
      defer { isPurchasing = false }

      do {
         let package = try await fetchPremiumPackage()
         guard let package else {
            handlePremiumPurchaseResult(.missingPackage, analyticsSource: "purchase")
            return
         }

         let result = try await premiumPurchaseService.purchase(package: package)
         handlePremiumPurchaseResult(result, analyticsSource: "purchase")
      } catch {
         purchaseMessage = PurchaseMessage(title: String(localized: "PremiumPurchaseFailedTitle"), message: error.localizedDescription)
         FAAnalytics.log(.track(.premiumPurchaseFailed, parameters: premiumAnalyticsParameters(source: "purchase").merging([
            .errorDescription: error.localizedDescription
         ])))
      }
   }

   private func restorePremiumPurchases() async {
      defer { isRestoring = false }

      do {
         let result = try await premiumPurchaseService.restorePurchases()
         handlePremiumRestoreResult(result)
      } catch {
         purchaseMessage = PurchaseMessage(title: String(localized: "RestorePurchaseFailedTitle"), message: error.localizedDescription)
         FAAnalytics.log(.track(.premiumRestoreFailed, parameters: premiumAnalyticsParameters(source: "restore").merging([
            .errorDescription: error.localizedDescription
         ])))
      }
   }

   /// 旧UserDefaults配列形式の好き嫌いを現在の人物・記録形式へ移行する。
   private static func migratedLegacyData(defaults: UserDefaults, now: Date) -> (persons: [Person], entries: [LikeDislikeItem]) {
      let me = makeMePerson(now: now, sortOrder: 0)
      let legacyLikes = defaults.stringArray(forKey: EntryKind.like.storageKey) ?? []
      let legacyHates = defaults.stringArray(forKey: EntryKind.hate.storageKey) ?? []

      let likeItems = legacyLikes.enumerated().map { offset, title in
         LikeDislikeItem(
            id: UUID(),
            personId: me.id,
            type: .like,
            title: title,
            note: nil,
            createdAt: now,
            updatedAt: now,
            sortOrder: offset
         )
      }

      let hateItems = legacyHates.enumerated().map { offset, title in
         LikeDislikeItem(
            id: UUID(),
            personId: me.id,
            type: .hate,
            title: title,
            note: nil,
            createdAt: now,
            updatedAt: now,
            sortOrder: offset
         )
      }

      return ([me], likeItems + hateItems)
   }

   /// 初期人物として使う「わたし」を生成する。
   static func makeMePerson(now: Date, sortOrder: Int) -> Person {
      Person(
         id: UUID(),
         name: String(localized: "DefaultMeName"),
         profileImageName: DefaultProfileImage.random().rawValue,
         photoFileName: nil,
         isMe: true,
         createdAt: now,
         updatedAt: now,
         sortOrder: sortOrder
      )
   }

   /// 既存人物データを並び順、`isMe`、旧表示名、プリセット画像の観点で補正する。
   static func normalizedPersons(_ rawPersons: [Person], now: Date) -> [Person] {
      var normalized = rawPersons.sorted {
         if $0.sortOrder == $1.sortOrder {
            return $0.createdAt < $1.createdAt
         }
         return $0.sortOrder < $1.sortOrder
      }
      guard !normalized.isEmpty else {
         return [makeMePerson(now: now, sortOrder: 0)]
      }

      var foundMe = false
      for index in normalized.indices {
         if normalized[index].isMe {
            if foundMe {
               normalized[index].isMe = false
            } else {
               foundMe = true
            }
         }
         normalized[index].sortOrder = index
      }

      if !foundMe {
         normalized[0].isMe = true
         normalized[0].name = String(localized: "DefaultMeName")
         normalized[0].updatedAt = now
      }

      for index in normalized.indices where normalized[index].isMe && isLegacyMeName(normalized[index].name) {
         normalized[index].name = String(localized: "DefaultMeName")
         normalized[index].updatedAt = now
      }

      for index in normalized.indices where DefaultProfileImage(rawValue: normalized[index].profileImageName ?? "") == nil {
         normalized[index].profileImageName = DefaultProfileImage.random().rawValue
         normalized[index].updatedAt = now
      }

      return normalized
   }

   private static func isLegacyMeName(_ name: String) -> Bool {
      let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmedName.isEmpty || trimmedName == "自分"
   }

   /// 人物と各人物の記録の並び順を連番に補正する。
   func normalizeSortOrders() {
      for index in persons.indices {
         persons[index].sortOrder = index
      }

      for person in persons {
         for kind in EntryKind.allCases {
            renumberItems(personID: person.id, kind: kind)
         }
      }
   }

   private func renumberItems(personID: UUID, kind: EntryKind) {
      let orderedItems = items(for: personID, kind: kind)
      for (sortOrder, item) in orderedItems.enumerated() {
         guard let index = entries.firstIndex(where: { $0.id == item.id }) else { continue }
         entries[index].sortOrder = sortOrder
      }
   }

   private func nextPersonSortOrder() -> Int {
      (persons.map(\.sortOrder).max() ?? -1) + 1
   }

   private func nextItemSortOrder(personID: UUID, kind: EntryKind) -> Int {
      (items(for: personID, kind: kind).map(\.sortOrder).max() ?? -1) + 1
   }

   private func sanitizedPersonName(_ rawName: String) -> String {
      PersonNameRules.sanitized(rawName)
   }

   private func uniqueComparisonTitles(from items: [LikeDislikeItem]) -> [(title: String, key: String)] {
      var seen = Set<String>()
      var titles: [(title: String, key: String)] = []

      for item in items {
         let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
         let key = title.lowercased()
         guard !title.isEmpty, !seen.contains(key) else { continue }
         seen.insert(key)
         titles.append((title, key))
      }

      return titles
   }

   /// 選択写真を丸アイコン表示向けの正方形サムネイルJPEGへ変換する。
   static func thumbnailPhotoData(from data: Data) -> Data? {
      guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }

      let targetSize = Constants.personPhotoSize
      let scale = max(targetSize.width / image.size.width, targetSize.height / image.size.height)
      let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
      let drawOrigin = CGPoint(
         x: (targetSize.width - drawSize.width) / 2,
         y: (targetSize.height - drawSize.height) / 2
      )

      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true

      let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
      let thumbnail = renderer.image { _ in
         UIColor.systemBackground.setFill()
         UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
         image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
      }

      return thumbnail.jpegData(compressionQuality: 0.86)
   }

   private static func savePhotoData(_ data: Data, personID: UUID) -> String? {
      guard let thumbnailData = thumbnailPhotoData(from: data) else { return nil }

      do {
         let directoryURL = try photosDirectoryURL()
         let fileName = photoFileName(for: personID)
         let fileURL = directoryURL.appendingPathComponent(fileName)
         try thumbnailData.write(to: fileURL, options: .atomic)
         return fileName
      } catch {
         return nil
      }
   }

   private static func photoURL(fileName: String) -> URL? {
      try? photosDirectoryURL().appendingPathComponent(fileName)
   }

   private static func photoFileName(for personID: UUID) -> String {
      "person_\(personID.uuidString).jpg"
   }

   private static func photosDirectoryURL() throws -> URL {
      let directoryURL = try FileManager.default
         .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
         .appendingPathComponent(Constants.personPhotosDirectoryName, isDirectory: true)
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      return directoryURL
   }

   private static func deletePhotoFile(named fileName: String?) {
      guard let fileName, let url = photoURL(fileName: fileName) else { return }
      try? FileManager.default.removeItem(at: url)
   }

   private static func deleteAllPhotoFiles() {
      guard let directoryURL = try? photosDirectoryURL() else { return }
      try? FileManager.default.removeItem(at: directoryURL)
   }

   private static func decode<T: Decodable>(_ type: T.Type, forKey key: String, defaults: UserDefaults) -> T? {
      guard let data = defaults.data(forKey: key) else { return nil }
      return try? JSONDecoder().decode(type, from: data)
   }

   /// 人物と記録を永続化し、現在の移行バージョンを書き込む。
   func persistPeopleAndEntries() {
      persistPersons()
      persistEntries()
      defaults.set(Constants.currentDataMigrationVersion, forKey: Constants.dataMigrationVersionKey)
   }

   private func persistPersons() {
      persist(persons, forKey: Constants.personsKey)
   }

   private func persistEntries() {
      persist(entries, forKey: Constants.itemsKey)
   }

   private func persist<T: Encodable>(_ value: T, forKey key: String) {
      guard let data = try? JSONEncoder().encode(value) else { return }
      defaults.set(data, forKey: key)
   }

   private func setAdRemoved(_ value: Bool) {
      didBuyRemoveAd = value
      defaults.set(value, forKey: Constants.adRemovedKey)
      if value {
         setPremiumPurchased(true)
      }
      NotificationCenter.default.post(name: .didRemoveAds, object: nil)
   }

   private func setPremiumPurchased(_ value: Bool) {
      didBuyPremium = value || didBuyRemoveAd
      defaults.set(didBuyPremium, forKey: Constants.premiumPurchasedKey)
      if value {
         NotificationCenter.default.post(name: .didRemoveAds, object: nil)
      }
   }

   private func applyPremiumEntitlement(isActive: Bool) {
      setPremiumPurchased(isActive)
   }

   private func handlePremiumPurchaseResult(_ result: PremiumPurchaseResult, analyticsSource: String) {
      switch result {
      case .active:
         setPremiumPurchased(true)
         purchaseMessage = PurchaseMessage(title: String(localized: "PremiumPurchaseSucceededTitle"), message: String(localized: "PremiumPurchaseSucceededMessage"))
         let parameters = premiumAnalyticsParameters(source: analyticsSource).merging([
            .source: analyticsSource,
            .personCount: persons.count,
            .productID: LikehateRevenueCatContracts.premiumProductID
         ])
         FAAnalytics.log(.track(.premiumPurchaseSucceeded, parameters: parameters))
         FAAnalytics.log(.purchase(
            productID: LikehateRevenueCatContracts.premiumProductID,
            price: premiumProductPrice,
            parameters: parameters
         ))
         HapticsClient.success()
      case .userCancelled:
         FAAnalytics.log(.track(.premiumPurchaseCancelled, parameters: [
            .source: analyticsSource
         ]))
      case .inactive, .missingCustomerInfo, .missingEntitlement, .missingPackage:
         setPremiumPurchased(false)
         purchaseMessage = PurchaseMessage(title: String(localized: "PremiumPurchaseFailedTitle"), message: String(localized: "PremiumPurchaseUnavailableMessage"))
         FAAnalytics.log(.track(.premiumPurchaseFailed, parameters: premiumAnalyticsParameters(source: analyticsSource).merging([
            .source: analyticsSource,
            .reason: String(describing: result)
         ])))
         HapticsClient.error()
      }
   }

   private func handlePremiumRestoreResult(_ result: PremiumPurchaseResult) {
      switch result {
      case .active:
         setPremiumPurchased(true)
         purchaseMessage = PurchaseMessage(title: String(localized: "RestorePurchaseSucceededTitle"), message: String(localized: "RestorePurchaseSucceededMessage"))
         FAAnalytics.log(.track(.premiumRestoreSucceeded, parameters: [
            .isPremium: hasPremiumAccess
         ]))
         HapticsClient.success()
      case .userCancelled:
         FAAnalytics.log(.track(.premiumRestoreCancelled, parameters: nil))
      case .inactive, .missingCustomerInfo, .missingEntitlement, .missingPackage:
         setPremiumPurchased(false)
         if hasPremiumAccess {
            purchaseMessage = PurchaseMessage(title: String(localized: "RestorePurchaseSucceededTitle"), message: String(localized: "RestorePurchaseSucceededMessage"))
            FAAnalytics.log(.track(.premiumLegacyRestoreSucceeded, parameters: nil))
         } else {
            purchaseMessage = PurchaseMessage(title: String(localized: "RestorePurchaseEmptyTitle"), message: String(localized: "RestorePurchaseEmptyMessage"))
            FAAnalytics.log(.track(.premiumRestoreEmpty, parameters: [
               .reason: String(describing: result)
            ]))
         }
      }
   }

   private func observePremiumEntitlementUpdates() {
      premiumEntitlementObserver = NotificationCenter.default.addObserver(
         forName: .didUpdatePremiumEntitlement,
         object: nil,
         queue: .main
      ) { [weak self] notification in
         guard let isPremiumActive = notification.userInfo?[PremiumEntitlementNotificationUserInfoKey.isPremiumActive] as? Bool else { return }
         Task { @MainActor in
            self?.applyPremiumEntitlement(isActive: isPremiumActive)
         }
      }
   }

   private func recordRegistrationAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.registrationReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.registrationReviewRequestCountKey)

      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByRegistrationCount")
   }

   private func requestReviewIfNeeded(count: Int, eventName: String) {
      guard count == 10 || count == 20 else { return }

      FAAnalytics.log(.track(.reviewPromptRequested, parameters: [
         .trigger: eventName,
         .count: count,
         .likeCount: likes.count,
         .hateCount: hates.count,
         .entryCount: entries.count
      ]))
      AppReviewClient.requestReview()
   }

   private func analyticsParameters(for kind: EntryKind, personID: UUID, textLength: Int? = nil, entryText: String? = nil) -> FAParameters {
      analyticsParameters(for: kind, person: person(for: personID), textLength: textLength, entryText: entryText)
   }

   private func analyticsParameters(for kind: EntryKind, person: Person?, textLength: Int? = nil, entryText: String? = nil) -> FAParameters {
      let personItems = person.map { items(for: $0.id, kind: kind).count } ?? 0
      var parameters: FAParameters = [
         .kind: kind.rawValue,
         .kindCount: personItems,
         .likeCount: likes.count,
         .hateCount: hates.count,
         .entryCount: entries.count,
         .personCount: persons.count,
         .totalCount: likes.count + hates.count
      ]

      if let person {
         parameters[.personID] = person.id.uuidString
         parameters[.isMe] = person.isMe
      }

      if let textLength {
         parameters[.textLength] = textLength
      }

      if let entryText = entryText.flatMap({ FAEntryTextParameter.value(from: $0) }) {
         parameters[.entryText] = entryText
      }

      return parameters
   }

   private func personAnalyticsParameters(_ person: Person, source: String, profileImageSource: FAProfileImageSource? = nil) -> FAParameters {
      var parameters: FAParameters = [
         .personID: person.id.uuidString,
         .isMe: person.isMe,
         .personCount: persons.count,
         .entryCount: entries.count,
         .profileImage: person.profileImage.rawValue,
         .source: source
      ]

      if let personName = FAPersonNameParameter.value(from: person.name) {
         parameters[.personName] = personName
      }

      if let profileImageSource {
         parameters[.profileImageSource] = profileImageSource.rawValue
      }

      return parameters
   }

   private func resolvedProfileImageSourceForUpdate(
      person: Person,
      profileImage: DefaultProfileImage?,
      photoData: Data?,
      removesPhoto: Bool
   ) -> FAProfileImageSource {
      if photoData != nil {
         return .selectedPhoto
      }

      if profileImage != nil || removesPhoto {
         return .selectedPreset
      }

      return person.photoFileName == nil ? .existingPreset : .existingPhoto
   }

   private func premiumAnalyticsParameters(source: String) -> FAParameters {
      [
         .source: source,
         .personCount: persons.count,
         .entryCount: entries.count,
         .didBuyRemoveAd: didBuyRemoveAd,
         .didBuyPremium: didBuyPremium,
         .hasPremiumAccess: hasPremiumAccess
      ]
   }
}
