import FirebaseAnalytics
import Foundation
import SwiftUI
import SwiftyStoreKit
import UIKit

@MainActor
final class LikeHateStore: ObservableObject {
   private enum Constants {
      static let noAdsProductID = "NO_ADS_LIKEHATE"
      static let receiptSharedSecret = "50822b94b56840bb845871be8d3352ab"
      static let launchReviewRequestCountKey = "LaunchReviewRequestCount"
      static let registrationReviewRequestCountKey = "RegistrationReviewRequestCount"
      static let personsKey = "LikehatePersonsV1"
      static let itemsKey = "LikehateItemsV1"
      static let dataMigrationVersionKey = "LikehateDataMigrationVersion"
      static let currentDataMigrationVersion = 1
      static let animationEnabledKey = "AnimationEnabled"
      static let hapticsEnabledKey = "HapticsEnabled"
      static let adRemovedKey = "BuyRemoveAd"
      static let textSizeKey = "AppTextSize"
      static let personPhotosDirectoryName = "PersonPhotos"
      static let personPhotoSize = CGSize(width: 512, height: 512)

      #if DEBUG
      static let appStoreScreenshotModeEnabledKey = "DebugAppStoreScreenshotModeEnabled"
      static let appStoreScreenshotBackupPersonsKey = "DebugAppStoreScreenshotBackupPersonsV1"
      static let appStoreScreenshotBackupItemsKey = "DebugAppStoreScreenshotBackupItemsV1"
      #endif
   }

   @Published private(set) var persons: [Person]
   @Published private(set) var entries: [LikeDislikeItem]
   @Published var didBuyRemoveAd: Bool
   @Published var animationEnabled: Bool {
      didSet {
         defaults.set(animationEnabled, forKey: Constants.animationEnabledKey)
      }
   }
   @Published var textSize: AppTextSize {
      didSet {
         defaults.set(textSize.rawValue, forKey: Constants.textSizeKey)
      }
   }
   @Published var purchaseMessage: PurchaseMessage?
   @Published var reviewPrompt: ReviewPrompt?
   @Published var isPurchasing = false
   @Published var isRestoring = false

   #if DEBUG
   @Published private(set) var isAppStoreScreenshotModeEnabled: Bool
   #endif

   private let defaults: UserDefaults

   init(defaults: UserDefaults = .standard) {
      self.defaults = defaults
      self.didBuyRemoveAd = defaults.bool(forKey: Constants.adRemovedKey)
      self.animationEnabled = defaults.object(forKey: Constants.animationEnabledKey) as? Bool ?? true
      self.textSize = AppTextSize(rawValue: defaults.string(forKey: Constants.textSizeKey) ?? "") ?? .standard
      #if DEBUG
      self.isAppStoreScreenshotModeEnabled = defaults.bool(forKey: Constants.appStoreScreenshotModeEnabledKey)
      #endif

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
   }

   var mePerson: Person? {
      persons.first(where: \.isMe)
   }

   var likes: [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: .like).map(\.title)
   }

   var hates: [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: .hate).map(\.title)
   }

   var totalItemCount: Int {
      entries.count
   }

   var appSettings: AppSettings {
      AppSettings(
         animationEnabled: animationEnabled,
         vibrationEnabled: defaults.object(forKey: Constants.hapticsEnabledKey) as? Bool ?? true,
         adsRemoved: didBuyRemoveAd,
         textSize: textSize
      )
   }

   func typography(for dynamicTypeSize: DynamicTypeSize) -> AppTypography {
      AppTypography(textSize: textSize, dynamicTypeSize: dynamicTypeSize)
   }

   var layoutMetrics: AppLayoutMetrics {
      AppLayoutMetrics(textSize: textSize)
   }

   func defaultProfileImageForNewPerson() -> DefaultProfileImage {
      let usedImages = Set(persons.map(\.profileImage))
      return DefaultProfileImage.firstAvailable(excluding: usedImages)
   }

   func person(for id: UUID) -> Person? {
      persons.first { $0.id == id }
   }

   func items(for kind: EntryKind) -> [String] {
      guard let mePerson else { return [] }
      return items(for: mePerson.id, kind: kind).map(\.title)
   }

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

   func photoURL(for person: Person) -> URL? {
      guard let photoFileName = person.photoFileName else { return nil }
      guard let url = Self.photoURL(fileName: photoFileName) else { return nil }
      return FileManager.default.fileExists(atPath: url.path) ? url : nil
   }

   func photoImage(for person: Person) -> UIImage? {
      guard let photoURL = photoURL(for: person) else { return nil }
      return UIImage(contentsOfFile: photoURL.path)
   }

   func addPerson(named rawName: String, profileImage: DefaultProfileImage = .random(), photoData: Data? = nil) -> Person? {
      let name = sanitizedPersonName(rawName)
      guard !name.isEmpty else { return nil }

      let now = Date()
      let personID = UUID()
      let photoFileName = photoData.flatMap { Self.savePhotoData($0, personID: personID) }
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

      Analytics.logEvent("person_added", parameters: personAnalyticsParameters(person, source: "add"))
      HapticsClient.success()
      return person
   }

   func updatePerson(_ personID: UUID, name rawName: String, profileImage: DefaultProfileImage? = nil, photoData: Data? = nil, removesPhoto: Bool = false) {
      let name = sanitizedPersonName(rawName)
      guard !name.isEmpty, let index = persons.firstIndex(where: { $0.id == personID }) else { return }

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

      Analytics.logEvent("person_updated", parameters: personAnalyticsParameters(persons[index], source: "edit"))
      HapticsClient.success()
   }

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
      parameters["deleted_item_count"] = deletedItemCount
      Analytics.logEvent("person_deleted", parameters: parameters)
      HapticsClient.success()
   }

   func add(_ text: String, to kind: EntryKind) {
      guard let mePerson else { return }
      add(text, to: kind, personID: mePerson.id)
   }

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

      Analytics.logEvent(kind.analyticsName, parameters: analyticsParameters(for: kind, person: person, textLength: trimmed.count))
      Analytics.logEvent("entry_saved", parameters: analyticsParameters(for: kind, person: person, textLength: trimmed.count))
      HapticsClient.success()
      recordRegistrationAndRequestReviewIfNeeded()
   }

   @discardableResult
   func updateItem(_ itemID: UUID, title rawTitle: String) -> Bool {
      let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !title.isEmpty, let index = entries.firstIndex(where: { $0.id == itemID }) else { return false }

      entries[index].title = title
      entries[index].updatedAt = Date()
      persistEntries()

      Analytics.logEvent("entry_updated", parameters: analyticsParameters(for: entries[index].type, personID: entries[index].personId, textLength: title.count))
      HapticsClient.success()
      return true
   }

   func recordLaunchAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.launchReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.launchReviewRequestCountKey)

      Analytics.logEvent("app_launch_count_recorded", parameters: [
         "launch_count": nextCount,
         "like_count": likes.count,
         "hate_count": hates.count,
         "entry_count": entries.count,
         "person_count": persons.count,
         "did_buy_remove_ad": didBuyRemoveAd
      ])
      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByLaunchCount")
   }

   func delete(at offsets: IndexSet, from kind: EntryKind) {
      guard let mePerson else { return }
      delete(at: offsets, from: kind, personID: mePerson.id)
   }

   func delete(at offsets: IndexSet, from kind: EntryKind, personID: UUID) {
      let orderedItems = items(for: personID, kind: kind)
      let deletedIDs = offsets.compactMap { offset in
         orderedItems.indices.contains(offset) ? orderedItems[offset].id : nil
      }
      guard !deletedIDs.isEmpty else { return }

      entries.removeAll { deletedIDs.contains($0.id) }
      renumberItems(personID: personID, kind: kind)
      persistEntries()

      Analytics.logEvent("entry_deleted", parameters: analyticsParameters(for: kind, personID: personID).merging([
         "deleted_count": deletedIDs.count
      ]) { _, new in new })
   }

   func move(from source: IndexSet, to destination: Int, in kind: EntryKind) {
      guard let mePerson else { return }
      move(from: source, to: destination, in: kind, personID: mePerson.id)
   }

   func move(from source: IndexSet, to destination: Int, in kind: EntryKind, personID: UUID) {
      var orderedItems = items(for: personID, kind: kind)
      orderedItems.move(fromOffsets: source, toOffset: destination)

      for (sortOrder, item) in orderedItems.enumerated() {
         guard let index = entries.firstIndex(where: { $0.id == item.id }) else { continue }
         entries[index].sortOrder = sortOrder
         entries[index].updatedAt = Date()
      }
      persistEntries()

      Analytics.logEvent("entry_reordered", parameters: analyticsParameters(for: kind, personID: personID).merging([
         "moved_count": source.count,
         "destination": destination
      ]) { _, new in new })
   }

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

      Analytics.logEvent("delete all date", parameters: nil)
      Analytics.logEvent("all_entries_deleted", parameters: [
         "like_count": likeCount,
         "hate_count": hateCount,
         "total_count": likeCount + hateCount,
         "person_count": personCount
      ])
   }

   #if DEBUG
   func setAppStoreScreenshotModeEnabled(_ isEnabled: Bool) {
      guard isEnabled != isAppStoreScreenshotModeEnabled else { return }

      if isEnabled {
         enableAppStoreScreenshotMode()
      } else {
         restoreDataFromAppStoreScreenshotMode()
      }
   }
   #endif

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

   func purchaseNoAds() {
      guard !isPurchasing else { return }
      isPurchasing = true
      Analytics.logEvent("TapNoAdsInClearView", parameters: nil)
      Analytics.logEvent("purchase_no_ads_started", parameters: [
         "did_buy_remove_ad": didBuyRemoveAd
      ])

      SwiftyStoreKit.purchaseProduct(Constants.noAdsProductID, quantity: 1, atomically: true) { [weak self] result in
         Task { @MainActor in
            guard let self else { return }
            self.isPurchasing = false

            switch result {
            case .success(let purchase):
               if purchase.needsFinishTransaction {
                  SwiftyStoreKit.finishTransaction(purchase.transaction)
               }
               self.setAdRemoved(true)
               self.verifyNoAdsPurchase()
               self.purchaseMessage = PurchaseMessage(title: String(localized: "Passed."), message: "Purchase complete")
               Analytics.logEvent("purchase_no_ads_succeeded", parameters: nil)
            case .error(let error):
               self.purchaseMessage = PurchaseMessage(title: "Purchase failed", message: error.localizedDescription)
               Analytics.logEvent("purchase_no_ads_failed", parameters: [
                  "error_code": error.code.rawValue
               ])
            case .deferred:
               self.purchaseMessage = PurchaseMessage(title: "Purchase deferred", message: "The purchase is pending approval.")
               Analytics.logEvent("purchase_no_ads_deferred", parameters: nil)
            }
         }
      }
   }

   func restorePurchases() {
      guard !isRestoring else { return }
      isRestoring = true
      Analytics.logEvent("restore_purchases_started", parameters: [
         "did_buy_remove_ad": didBuyRemoveAd
      ])

      SwiftyStoreKit.restorePurchases(atomically: true) { [weak self] results in
         Task { @MainActor in
            guard let self else { return }
            self.isRestoring = false

            if let error = results.restoreFailedPurchases.first?.0 {
               let nsError = error as NSError
               self.purchaseMessage = PurchaseMessage(title: "Restore failed", message: error.localizedDescription)
               Analytics.logEvent("restore_purchases_failed", parameters: [
                  "failed_count": results.restoreFailedPurchases.count,
                  "restored_count": results.restoredPurchases.count,
                  "error_domain": nsError.domain,
                  "error_code": nsError.code
               ])
            } else if results.restoredPurchases.contains(where: { $0.productId == Constants.noAdsProductID }) {
               self.setAdRemoved(true)
               self.purchaseMessage = PurchaseMessage(title: String(localized: "Passed."), message: "Restore successful")
               Analytics.logEvent("restore_purchases_succeeded", parameters: [
                  "restored_count": results.restoredPurchases.count
               ])
            } else {
               self.purchaseMessage = PurchaseMessage(title: "Restore", message: "No purchases were found.")
               Analytics.logEvent("restore_purchases_empty", parameters: [
                  "restored_count": results.restoredPurchases.count
               ])
            }
         }
      }
   }

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

   private static func makeMePerson(now: Date, sortOrder: Int) -> Person {
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

   #if DEBUG
   private static let appStoreScreenshotMeID = UUID(uuidString: "00000000-0000-0000-0000-000000000101") ?? UUID()
   private static let appStoreScreenshotSecondPersonID = UUID(uuidString: "00000000-0000-0000-0000-000000000102") ?? UUID()
   private static let appStoreScreenshotThirdPersonID = UUID(uuidString: "00000000-0000-0000-0000-000000000103") ?? UUID()

   private static func makeAppStoreScreenshotData(now: Date) -> (persons: [Person], entries: [LikeDislikeItem]) {
      let persons = [
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotMeID,
            name: String(localized: "DefaultMeName"),
            profileImage: .defaultProfileImage,
            isMe: true,
            now: now,
            sortOrder: 0
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotSecondPersonID,
            name: "あかり",
            profileImage: .defaultProfileImage6,
            isMe: false,
            now: now,
            sortOrder: 1
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotThirdPersonID,
            name: "はると",
            profileImage: .defaultProfileImage16,
            isMe: false,
            now: now,
            sortOrder: 2
         )
      ]

      let entries =
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotMeID,
            kind: .like,
            titles: [
               "おすし",
               "映画館",
               "夜の散歩",
               "カフェラテ",
               "チーズケーキ",
               "読書",
               "温泉",
               "ボードゲーム",
               "猫カフェ",
               "美術館",
               "ハンバーグ",
               "朝のラジオ",
               "花火",
               "パン屋めぐり",
               "雨上がりの空",
               "季節の果物",
               "静かな朝",
               "手帳を書く",
               "焼きたてのパン",
               "植物の世話",
               "夕方の音楽",
               "ほうじ茶",
               "小さな旅"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotMeID,
            kind: .hate,
            titles: [
               "早起き",
               "人混み",
               "辛すぎる料理",
               "満員電車",
               "虫",
               "大きな音",
               "長い行列",
               "冷たい雨",
               "急な予定変更",
               "煙草のにおい",
               "ホラー映画",
               "徹夜",
               "狭い席",
               "強い香水",
               "締め切り前の焦り",
               "冷めたごはん"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .like,
            titles: [
               "チーズケーキ",
               "映画館",
               "美術館",
               "カフェラテ",
               "おすし",
               "パン屋めぐり",
               "花火",
               "水族館",
               "手紙を書く",
               "夜景",
               "読書",
               "抹茶ラテ",
               "ピクニック",
               "古着屋めぐり",
               "温泉",
               "いちごタルト",
               "公園ランチ",
               "手作り雑貨",
               "星を見る",
               "アロマ",
               "写真を撮る",
               "小さな花束",
               "手作りクッキー",
               "雑貨屋さん",
               "夕焼け",
               "日記を書く",
               "ホットケーキ",
               "海の見えるカフェ",
               "やわらかい毛布"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .hate,
            titles: [
               "虫",
               "満員電車",
               "辛すぎる料理",
               "早起き",
               "大きな音",
               "煙草のにおい",
               "長い行列",
               "寒すぎる部屋",
               "ホラー映画",
               "炭酸飲料",
               "徹夜",
               "急な予定変更",
               "生たまねぎ",
               "濃すぎる味付け"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .like,
            titles: [
               "カレー",
               "夜の散歩",
               "ボードゲーム",
               "キャンプ",
               "おすし",
               "温泉",
               "ハンバーグ",
               "朝のラジオ",
               "雨上がりの空",
               "サウナ",
               "海辺のドライブ",
               "ギター",
               "映画館",
               "コーヒー",
               "花火",
               "ラーメン",
               "唐揚げ",
               "昼寝",
               "登山",
               "クラフトビール",
               "深夜ラジオ"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .hate,
            titles: [
               "トマト",
               "雨の日の外出",
               "大きな音",
               "早起き",
               "満員電車",
               "強い香水",
               "長い行列",
               "虫",
               "辛すぎる料理",
               "狭い席",
               "ピーマン",
               "冷たい雨",
               "寝不足",
               "急な予定変更",
               "煙草のにおい",
               "待ち時間",
               "熱すぎる飲み物",
               "細かい作業",
               "寝坊",
               "渋滞",
               "薄いコーヒー",
               "予定の詰め込み",
               "湿気",
               "ぬるいお風呂",
               "パクチー",
               "明るすぎる照明",
               "通知音"
            ],
            now: now
         )

      return (persons, entries)
   }

   private static func makeAppStoreScreenshotPerson(
      id: UUID,
      name: String,
      profileImage: DefaultProfileImage,
      isMe: Bool,
      now: Date,
      sortOrder: Int
   ) -> Person {
      Person(
         id: id,
         name: name,
         profileImageName: profileImage.rawValue,
         photoFileName: nil,
         isMe: isMe,
         createdAt: now.addingTimeInterval(TimeInterval(sortOrder)),
         updatedAt: now,
         sortOrder: sortOrder
      )
   }

   private static func makeAppStoreScreenshotEntries(
      personID: UUID,
      kind: EntryKind,
      titles: [String],
      now: Date
   ) -> [LikeDislikeItem] {
      titles.enumerated().map { offset, title in
         LikeDislikeItem(
            id: UUID(),
            personId: personID,
            type: kind,
            title: title,
            note: nil,
            createdAt: now.addingTimeInterval(TimeInterval(offset)),
            updatedAt: now,
            sortOrder: offset
         )
      }
   }
   #endif

   private static func normalizedPersons(_ rawPersons: [Person], now: Date) -> [Person] {
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

   #if DEBUG
   private func enableAppStoreScreenshotMode() {
      backupCurrentDataForAppStoreScreenshotMode()

      let sampleData = Self.makeAppStoreScreenshotData(now: Date())
      persons = sampleData.persons
      entries = sampleData.entries
      isAppStoreScreenshotModeEnabled = true
      defaults.set(true, forKey: Constants.appStoreScreenshotModeEnabledKey)
      persistPeopleAndEntries()
   }

   private func restoreDataFromAppStoreScreenshotMode() {
      let now = Date()
      if
         let backedUpPersons: [Person] = Self.decode([Person].self, forKey: Constants.appStoreScreenshotBackupPersonsKey, defaults: defaults),
         let backedUpEntries: [LikeDislikeItem] = Self.decode([LikeDislikeItem].self, forKey: Constants.appStoreScreenshotBackupItemsKey, defaults: defaults)
      {
         let restoredPersons = Self.normalizedPersons(backedUpPersons, now: now)
         let validPersonIDs = Set(restoredPersons.map(\.id))
         persons = restoredPersons
         entries = backedUpEntries.filter { validPersonIDs.contains($0.personId) }
         normalizeSortOrders()
      } else {
         persons = [Self.makeMePerson(now: now, sortOrder: 0)]
         entries = []
      }

      defaults.removeObject(forKey: Constants.appStoreScreenshotBackupPersonsKey)
      defaults.removeObject(forKey: Constants.appStoreScreenshotBackupItemsKey)
      isAppStoreScreenshotModeEnabled = false
      defaults.set(false, forKey: Constants.appStoreScreenshotModeEnabledKey)
      persistPeopleAndEntries()
   }

   private func backupCurrentDataForAppStoreScreenshotMode() {
      persist(persons, forKey: Constants.appStoreScreenshotBackupPersonsKey)
      persist(entries, forKey: Constants.appStoreScreenshotBackupItemsKey)
   }
   #endif

   private func normalizeSortOrders() {
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

   private func persistPeopleAndEntries() {
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
      NotificationCenter.default.post(name: .didRemoveAds, object: nil)
   }

   private func verifyNoAdsPurchase() {
      let validator = AppleReceiptValidator(service: .production, sharedSecret: Constants.receiptSharedSecret)
      SwiftyStoreKit.verifyReceipt(using: validator) { result in
         switch result {
         case .success(let receipt):
            let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: Constants.noAdsProductID, inReceipt: receipt)
            print("購入の検証: \(purchaseResult)")
         case .error(let error):
            print("verifyPurchaseエラー: \(error)")
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

      Analytics.logEvent(eventName, parameters: ["count": count])
      Analytics.logEvent("review_prompt_requested", parameters: [
         "trigger": eventName,
         "count": count,
         "like_count": likes.count,
         "hate_count": hates.count,
         "entry_count": entries.count
      ])
      AppReviewClient.requestReview()
   }

   private func analyticsParameters(for kind: EntryKind, personID: UUID, textLength: Int? = nil) -> [String: Any] {
      analyticsParameters(for: kind, person: person(for: personID), textLength: textLength)
   }

   private func analyticsParameters(for kind: EntryKind, person: Person?, textLength: Int? = nil) -> [String: Any] {
      let personItems = person.map { items(for: $0.id, kind: kind).count } ?? 0
      var parameters: [String: Any] = [
         "kind": kind.rawValue,
         "kind_count": personItems,
         "like_count": likes.count,
         "hate_count": hates.count,
         "entry_count": entries.count,
         "person_count": persons.count,
         "total_count": likes.count + hates.count
      ]

      if let person {
         parameters["person_id"] = person.id.uuidString
         parameters["is_me"] = person.isMe
      }

      if let textLength {
         parameters["text_length"] = textLength
      }

      return parameters
   }

   private func personAnalyticsParameters(_ person: Person, source: String) -> [String: Any] {
      [
         "person_id": person.id.uuidString,
         "is_me": person.isMe,
         "person_count": persons.count,
         "entry_count": entries.count,
         "source": source
      ]
   }
}
