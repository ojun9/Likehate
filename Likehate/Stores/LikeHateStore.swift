import Foundation
import SwiftUI
import UIKit

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

   @Published private(set) var persons: [Person]
   @Published private(set) var entries: [LikeDislikeItem]
   @Published var didBuyRemoveAd: Bool
   @Published var didBuyPremium: Bool
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
   @Published var premiumProductPrice: String?

   let defaults: UserDefaults
   private let premiumPurchaseService: PremiumPurchaseServicing
   private var premiumPackage: PremiumPackage?
   private var premiumEntitlementObserver: NSObjectProtocol?

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
         isPremium: didBuyPremium,
         textSize: textSize
      )
   }

   var premiumAccessPolicy: PremiumAccessPolicy {
      PremiumAccessPolicy(
         isPremium: didBuyPremium,
         adsRemoved: didBuyRemoveAd,
         personCount: persons.count
      )
   }

   var hasPremiumAccess: Bool {
      premiumAccessPolicy.hasPremiumAccess
   }

   var canAddPerson: Bool {
      premiumAccessPolicy.canAddPerson
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

   func replacePeopleAndEntries(persons newPersons: [Person], entries newEntries: [LikeDislikeItem]) {
      persons = newPersons
      entries = newEntries
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
      guard !name.isEmpty, canAddPerson else { return nil }

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

      FAAnalytics.log(.track(.personAdded, parameters: personAnalyticsParameters(person, source: "add")))
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

      FAAnalytics.log(.track(.personUpdated, parameters: personAnalyticsParameters(persons[index], source: "edit")))
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
      parameters[.deletedItemCount] = deletedItemCount
      FAAnalytics.log(.track(.personDeleted, parameters: parameters))
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

      FAAnalytics.log(.track(.entrySaved, parameters: analyticsParameters(for: kind, person: person, textLength: trimmed.count)))
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

      FAAnalytics.log(.track(.entryUpdated, parameters: analyticsParameters(for: entries[index].type, personID: entries[index].personId, textLength: title.count)))
      HapticsClient.success()
      return true
   }

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

      FAAnalytics.log(.track(.entryDeleted, parameters: analyticsParameters(for: kind, personID: personID).merging([
         .deletedCount: deletedIDs.count
      ])))
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

      FAAnalytics.log(.track(.entryReordered, parameters: analyticsParameters(for: kind, personID: personID).merging([
         .movedCount: source.count,
         .destination: destination
      ])))
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

      FAAnalytics.log(.track(.allEntriesDeleted, parameters: [
         .likeCount: likeCount,
         .hateCount: hateCount,
         .totalCount: likeCount + hateCount,
         .personCount: personCount
      ]))
   }

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

   func purchasePremium() {
      guard !isPurchasing, !hasPremiumAccess else { return }
      isPurchasing = true
      FAAnalytics.log(.track(.premiumPurchaseStarted, parameters: premiumAnalyticsParameters(source: "purchase")))

      Task {
         await purchasePremiumPackage()
      }
   }

   func restorePurchases() {
      guard !isRestoring else { return }
      isRestoring = true
      FAAnalytics.log(.track(.premiumRestoreStarted, parameters: premiumAnalyticsParameters(source: "restore")))

      Task {
         await restorePremiumPurchases()
      }
   }

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

   private func analyticsParameters(for kind: EntryKind, personID: UUID, textLength: Int? = nil) -> FAParameters {
      analyticsParameters(for: kind, person: person(for: personID), textLength: textLength)
   }

   private func analyticsParameters(for kind: EntryKind, person: Person?, textLength: Int? = nil) -> FAParameters {
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

      return parameters
   }

   private func personAnalyticsParameters(_ person: Person, source: String) -> FAParameters {
      [
         .personID: person.id.uuidString,
         .isMe: person.isMe,
         .personCount: persons.count,
         .entryCount: entries.count,
         .source: source
      ]
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
