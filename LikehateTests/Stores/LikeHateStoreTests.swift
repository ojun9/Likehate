import Foundation
import Testing
import UIKit
@testable import Likehate

@MainActor
struct LikeHateStorePersonTests {
   @Test("A fresh store creates one protected me person with a default profile image")
   func freshStoreCreatesMePerson() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      #expect(store.persons.count == 1)
      #expect(me.isMe)
      #expect(me.displayName.isEmpty == false)
      #expect(DefaultProfileImage(rawValue: me.profileImageName ?? "") != nil)
      #expect(me.photoFileName == nil)
   }

   @Test("Adding a person trims the name, stores the selected profile image, and persists")
   func addPersonPersistsProfileImage() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let person = try #require(store.addPerson(named: "  太郎  ", profileImage: .defaultProfileImage7))

      #expect(person.name == "太郎")
      #expect(person.isMe == false)
      #expect(person.profileImageName == DefaultProfileImage.defaultProfileImage7.rawValue)

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      let reloadedPerson = try #require(reloadedStore.person(for: person.id))
      #expect(reloadedPerson.name == "太郎")
      #expect(reloadedPerson.profileImageName == DefaultProfileImage.defaultProfileImage7.rawValue)
   }

   @Test("Adding and updating a person limits names to forty characters")
   func addAndUpdatePersonLimitNamesToFortyCharacters() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let longName = String(repeating: "あ", count: 41)
      let person = try #require(store.addPerson(named: "  \(longName)  ", profileImage: .defaultProfileImage7))

      #expect(person.name.count == 40)
      #expect(person.name == String(repeating: "あ", count: 40))

      let updateName = String(repeating: "い", count: 45)
      store.updatePerson(person.id, name: updateName, profileImage: .defaultProfileImage8)
      let updatedPerson = try #require(store.person(for: person.id))

      #expect(updatedPerson.name.count == 40)
      #expect(updatedPerson.name == String(repeating: "い", count: 40))
   }

   @Test("Updating me stores and displays a custom name")
   func updateMeStoresAndDisplaysCustomName() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.updatePerson(me.id, name: "別名", profileImage: .defaultProfileImage4)
      let updatedMe = try #require(store.mePerson)

      #expect(updatedMe.name == "別名")
      #expect(updatedMe.displayName == "別名")
      #expect(updatedMe.profileImageName == DefaultProfileImage.defaultProfileImage4.rawValue)
   }

   @Test("Updating another person changes the stored and display name")
   func updateOtherPersonChangesStoredAndDisplayName() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3))

      store.updatePerson(friend.id, name: "  あかり  ", profileImage: .defaultProfileImage8)
      let updatedFriend = try #require(store.person(for: friend.id))

      #expect(updatedFriend.name == "あかり")
      #expect(updatedFriend.displayName == "あかり")
      #expect(updatedFriend.profileImageName == DefaultProfileImage.defaultProfileImage8.rawValue)
   }

   @Test("Blank person updates are rejected without changing profile image")
   func blankPersonUpdatesAreRejected() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3))

      store.updatePerson(friend.id, name: "   ", profileImage: .defaultProfileImage8)
      let unchangedFriend = try #require(store.person(for: friend.id))

      #expect(unchangedFriend.name == "太郎")
      #expect(unchangedFriend.profileImageName == DefaultProfileImage.defaultProfileImage3.rawValue)
   }

   @Test("Deleting a person removes their entries but keeps me protected")
   func deletePersonRemovesTheirEntriesOnly() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3))

      store.add("おすし", to: .like, personID: me.id)
      store.add("ラーメン", to: .like, personID: friend.id)
      store.add("雨", to: .hate, personID: friend.id)

      store.deletePerson(me.id)
      #expect(store.person(for: me.id) != nil)

      store.deletePerson(friend.id)
      #expect(store.person(for: friend.id) == nil)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["おすし"])
      #expect(store.items(for: friend.id, kind: .like).isEmpty)
      #expect(store.items(for: friend.id, kind: .hate).isEmpty)
   }

   @Test("Stored people are normalized, keep one me person, and filter orphan entries")
   func storedPeopleAreNormalized() throws {
      let meID = UUID()
      let duplicateMeID = UUID()
      let orphanID = UUID()
      let now = Date()
      let storedPersons = [
         makeStoredPerson(id: duplicateMeID, name: "太郎", profileImageName: DefaultProfileImage.defaultProfileImage4.rawValue, isMe: true, createdAt: now.addingTimeInterval(10), sortOrder: 1),
         makeStoredPerson(id: meID, name: "自分", profileImageName: nil, isMe: true, createdAt: now, sortOrder: 0)
      ]
      let storedItems = [
         makeStoredItem(personID: meID, kind: .like, title: "おすし", sortOrder: 0),
         makeStoredItem(personID: orphanID, kind: .hate, title: "消える", sortOrder: 0)
      ]
      let context = try StoreTestContext(initialValues: { defaults in
         try? storeEncoded(storedPersons, forKey: "LikehatePersonsV1", defaults: defaults)
         try? storeEncoded(storedItems, forKey: "LikehateItemsV1", defaults: defaults)
      })
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.person(for: meID))
      let duplicateMe = try #require(store.person(for: duplicateMeID))

      #expect(store.persons.count == 2)
      #expect(store.persons.filter(\.isMe).count == 1)
      #expect(me.isMe)
      #expect(me.name == String(localized: "DefaultMeName"))
      #expect(me.displayName == String(localized: "DefaultMeName"))
      #expect(DefaultProfileImage(rawValue: me.profileImageName ?? "") != nil)
      #expect(duplicateMe.isMe == false)
      #expect(store.entries.map(\.title) == ["おすし"])
   }
}

@MainActor
struct LikeHateStoreEntryTests {
   @Test("Entries trim whitespace, reject empty text, update, move, and delete")
   func entryLifecycle() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("  おすし  ", to: .like, personID: me.id)
      store.add("   ", to: .like, personID: me.id)
      store.add("カレー", to: .like, personID: me.id)

      var likes = store.items(for: me.id, kind: .like)
      #expect(likes.map(\.title) == ["おすし", "カレー"])

      let firstItem = try #require(likes.first)
      #expect(store.updateItem(firstItem.id, title: "  お寿司  "))
      #expect(store.updateItem(firstItem.id, title: "   ") == false)

      likes = store.items(for: me.id, kind: .like)
      #expect(likes.map(\.title) == ["お寿司", "カレー"])

      store.move(from: IndexSet(integer: 0), to: 2, in: .like, personID: me.id)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["カレー", "お寿司"])

      store.delete(at: IndexSet(integer: 0), from: .like, personID: me.id)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["お寿司"])
   }

   @Test("Entry preview follows reordered list order")
   func entryPreviewFollowsReorderedListOrder() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("おすし", to: .like, personID: me.id)
      store.add("カレー", to: .like, personID: me.id)
      store.add("映画", to: .like, personID: me.id)
      store.add("散歩", to: .like, personID: me.id)

      #expect(EntryPreviewItems.items(from: store.items(for: me.id, kind: .like)).map(\.title) == ["おすし", "カレー", "映画"])

      store.move(from: IndexSet(integer: 3), to: 0, in: .like, personID: me.id)

      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["散歩", "おすし", "カレー", "映画"])
      #expect(EntryPreviewItems.items(from: store.items(for: me.id, kind: .like)).map(\.title) == ["散歩", "おすし", "カレー"])
   }

   @Test("Legacy like and hate arrays migrate into the me person")
   func legacyDataMigratesIntoMePerson() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(["おすし", "カレー"], forKey: EntryKind.like.storageKey)
         defaults.set(["雨"], forKey: EntryKind.hate.storageKey)
      })
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["おすし", "カレー"])
      #expect(store.items(for: me.id, kind: .hate).map(\.title) == ["雨"])
      #expect(DefaultProfileImage(rawValue: me.profileImageName ?? "") != nil)
   }
}

@MainActor
struct LikeHateStorePhotoTests {
   @Test("Photo data is converted into a square JPEG thumbnail")
   func photoDataIsConvertedIntoSquareThumbnail() throws {
      let sourceData = try TestImageFactory.jpegData(size: CGSize(width: 80, height: 40), color: .systemPink)
      let thumbnailData = try #require(LikeHateStore.thumbnailPhotoData(from: sourceData))
      let thumbnail = try #require(UIImage(data: thumbnailData))

      #expect(Int(thumbnail.size.width) == 512)
      #expect(Int(thumbnail.size.height) == 512)
   }

   @Test("Invalid photo data is rejected")
   func invalidPhotoDataIsRejected() {
      #expect(LikeHateStore.thumbnailPhotoData(from: Data("not image".utf8)) == nil)
   }

   @Test("Person photo can be saved, loaded, removed, and deleted with the person")
   func personPhotoLifecycle() throws {
      let context = try StoreTestContext()
      defer {
         context.store.deleteAll()
         context.cleanup()
      }

      let store = context.store
      let photoData = try TestImageFactory.jpegData(size: CGSize(width: 72, height: 120), color: .systemBlue)
      let person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3, photoData: photoData))
      let storedPerson = try #require(store.person(for: person.id))
      let photoFileName = try #require(storedPerson.photoFileName)
      let photoURL = try #require(store.photoURL(for: storedPerson))

      #expect(photoFileName == "person_\(person.id.uuidString).jpg")
      #expect(FileManager.default.fileExists(atPath: photoURL.path))
      #expect(store.photoImage(for: storedPerson) != nil)

      store.updatePerson(person.id, name: "太郎", removesPhoto: true)
      let photoRemovedPerson = try #require(store.person(for: person.id))
      #expect(photoRemovedPerson.photoFileName == nil)
      #expect(FileManager.default.fileExists(atPath: photoURL.path) == false)

      let replacementData = try TestImageFactory.jpegData(size: CGSize(width: 60, height: 60), color: .systemGreen)
      store.updatePerson(person.id, name: "太郎", photoData: replacementData)
      let replacedPerson = try #require(store.person(for: person.id))
      let replacedPhotoURL = try #require(store.photoURL(for: replacedPerson))
      #expect(FileManager.default.fileExists(atPath: replacedPhotoURL.path))

      store.deletePerson(person.id)
      #expect(FileManager.default.fileExists(atPath: replacedPhotoURL.path) == false)
   }

   @Test("Preset profile image update removes an existing photo")
   func presetProfileImageUpdateRemovesExistingPhoto() throws {
      let context = try StoreTestContext()
      defer {
         context.store.deleteAll()
         context.cleanup()
      }

      let store = context.store
      let photoData = try TestImageFactory.jpegData(size: CGSize(width: 96, height: 96), color: .systemPurple)
      let person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3, photoData: photoData))
      let photoPerson = try #require(store.person(for: person.id))
      let photoURL = try #require(store.photoURL(for: photoPerson))

      store.updatePerson(person.id, name: "太郎", profileImage: .defaultProfileImage11, removesPhoto: true)
      let updatedPerson = try #require(store.person(for: person.id))

      #expect(updatedPerson.profileImageName == DefaultProfileImage.defaultProfileImage11.rawValue)
      #expect(updatedPerson.photoFileName == nil)
      #expect(FileManager.default.fileExists(atPath: photoURL.path) == false)
   }
}

@MainActor
struct LikeHateStoreComparisonTests {
   @Test("Comparison sections classify shared and person-only entries")
   func comparisonSectionsClassifyEntries() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage5))

      store.add("おすし", to: .like, personID: me.id)
      store.add("おすし", to: .like, personID: me.id)
      store.add("お茶", to: .like, personID: me.id)
      store.add("おすし", to: .like, personID: friend.id)
      store.add("ラーメン", to: .like, personID: friend.id)

      store.add("雨", to: .hate, personID: me.id)
      store.add("虫", to: .hate, personID: me.id)
      store.add("雨", to: .hate, personID: friend.id)
      store.add("煙", to: .hate, personID: friend.id)

      let sections = Dictionary(uniqueKeysWithValues: store
         .comparisonSections(firstPersonID: me.id, secondPersonID: friend.id)
         .map { ($0.category, $0.titles) })

      #expect(sections[.commonLike] == ["おすし"])
      #expect(sections[.firstOnlyLike] == ["お茶"])
      #expect(sections[.secondOnlyLike] == ["ラーメン"])
      #expect(sections[.commonHate] == ["雨"])
      #expect(sections[.firstOnlyHate] == ["虫"])
      #expect(sections[.secondOnlyHate] == ["煙"])
   }
}

@MainActor
struct LikeHateStoreSettingsTests {
   @Test("Default settings are conservative and readable")
   func defaultSettings() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let settings = context.store.appSettings

      #expect(settings.animationEnabled)
      #expect(settings.vibrationEnabled)
      #expect(settings.adsRemoved == false)
      #expect(settings.textSize == .standard)
   }

   @Test("Invalid stored text size falls back to standard")
   func invalidStoredTextSizeFallsBackToStandard() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set("giant", forKey: "AppTextSize")
      })
      defer { context.cleanup() }

      #expect(context.store.textSize == .standard)
   }

   @Test("Text size persists through UserDefaults and app settings")
   func textSizePersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.textSize = .extraLarge

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.textSize == .extraLarge)
      #expect(reloadedStore.appSettings.textSize == .extraLarge)
   }

   #if DEBUG
   @Test("App Store screenshot mode swaps in sample data and restores original data")
   func appStoreScreenshotModeSwapsAndRestoresOriginalData() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage8))
      store.add("焼き魚", to: .like, personID: friend.id)
      store.add("梅干し", to: .hate, personID: me.id)

      let originalPersonIDs = store.persons.map(\.id)
      let originalEntryTitles = store.entries.map(\.title)

      store.setAppStoreScreenshotModeEnabled(true)

      let sampleMe = try #require(store.mePerson)
      let sampleAkari = try #require(store.persons.first { $0.displayName == "あかり" })
      let sampleHaruto = try #require(store.persons.first { $0.displayName == "はると" })
      #expect(store.isAppStoreScreenshotModeEnabled)
      #expect(store.persons.map(\.displayName) == [String(localized: "DefaultMeName"), "あかり", "はると"])
      #expect(sampleHaruto.profileImageName == DefaultProfileImage.defaultProfileImage16.rawValue)
      #expect(store.items(for: sampleMe.id, kind: .like).count == 15)
      #expect(store.items(for: sampleMe.id, kind: .hate).count == 15)
      #expect(store.items(for: sampleAkari.id, kind: .like).count == 15)
      #expect(store.items(for: sampleAkari.id, kind: .hate).count == 15)
      #expect(store.items(for: sampleHaruto.id, kind: .like).count == 15)
      #expect(store.items(for: sampleHaruto.id, kind: .hate).count == 15)
      #expect(store.entries.count == 90)
      #expect(store.person(for: friend.id) == nil)

      let meAndAkariSections = Dictionary(uniqueKeysWithValues: store
         .comparisonSections(firstPersonID: sampleMe.id, secondPersonID: sampleAkari.id)
         .map { ($0.category, $0.titles) })
      #expect(meAndAkariSections[.commonLike]?.contains("映画館") == true)
      #expect(meAndAkariSections[.commonHate]?.contains("辛すぎる料理") == true)
      #expect(meAndAkariSections[.firstOnlyLike]?.contains("夜の散歩") == true)
      #expect(meAndAkariSections[.secondOnlyLike]?.contains("水族館") == true)

      store.setAppStoreScreenshotModeEnabled(false)

      #expect(store.isAppStoreScreenshotModeEnabled == false)
      #expect(store.persons.map(\.id) == originalPersonIDs)
      #expect(store.entries.map(\.title) == originalEntryTitles)
      #expect(store.items(for: friend.id, kind: .like).map(\.title) == ["焼き魚"])
      #expect(store.items(for: me.id, kind: .hate).map(\.title) == ["梅干し"])
   }

   @Test("App Store screenshot mode can restore after store reload")
   func appStoreScreenshotModeRestoresAfterReload() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      store.add("プリン", to: .like, personID: me.id)
      let originalPersonIDs = store.persons.map(\.id)

      store.setAppStoreScreenshotModeEnabled(true)

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.isAppStoreScreenshotModeEnabled)
      #expect(reloadedStore.persons.map(\.displayName) == [String(localized: "DefaultMeName"), "あかり", "はると"])

      reloadedStore.setAppStoreScreenshotModeEnabled(false)

      #expect(reloadedStore.isAppStoreScreenshotModeEnabled == false)
      #expect(reloadedStore.persons.map(\.id) == originalPersonIDs)
      #expect(reloadedStore.items(for: me.id, kind: .like).map(\.title) == ["プリン"])
   }
   #endif

   @Test("Delete all resets entries and recreates only me")
   func deleteAllResetsPeopleAndEntries() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      _ = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage8))
      store.add("おすし", to: .like, personID: me.id)
      store.add("雨", to: .hate, personID: me.id)

      store.deleteAll()

      let resetMe = try #require(store.mePerson)
      #expect(store.persons.count == 1)
      #expect(resetMe.isMe)
      #expect(store.items(for: resetMe.id, kind: .like).isEmpty)
      #expect(store.items(for: resetMe.id, kind: .hate).isEmpty)
      #expect(DefaultProfileImage(rawValue: resetMe.profileImageName ?? "") != nil)
   }
}

@MainActor
private struct StoreTestContext {
   let suiteName: String
   let defaults: UserDefaults
   let store: LikeHateStore

   init(initialValues: ((UserDefaults) -> Void)? = nil) throws {
      suiteName = "LikehateTests-\(UUID().uuidString)"
      guard let defaults = UserDefaults(suiteName: suiteName) else {
         throw StoreTestError.userDefaultsUnavailable
      }
      defaults.removePersistentDomain(forName: suiteName)
      initialValues?(defaults)

      self.defaults = defaults
      store = LikeHateStore(defaults: defaults)
   }

   func cleanup() {
      defaults.removePersistentDomain(forName: suiteName)
   }
}

private enum StoreTestError: Error {
   case userDefaultsUnavailable
}

private enum TestImageError: Error {
   case missingJPEGData
}

@MainActor
private enum TestImageFactory {
   static func jpegData(size: CGSize, color: UIColor) throws -> Data {
      let renderer = UIGraphicsImageRenderer(size: size)
      let image = renderer.image { context in
         color.setFill()
         context.fill(CGRect(origin: .zero, size: size))
      }

      guard let data = image.jpegData(compressionQuality: 0.9) else {
         throw TestImageError.missingJPEGData
      }
      return data
   }
}

private func makeStoredPerson(
   id: UUID = UUID(),
   name: String,
   profileImageName: String?,
   isMe: Bool,
   createdAt: Date = Date(),
   sortOrder: Int
) -> Person {
   Person(
      id: id,
      name: name,
      profileImageName: profileImageName,
      photoFileName: nil,
      isMe: isMe,
      createdAt: createdAt,
      updatedAt: createdAt,
      sortOrder: sortOrder
   )
}

private func makeStoredItem(
   personID: UUID,
   kind: EntryKind,
   title: String,
   sortOrder: Int
) -> LikeDislikeItem {
   LikeDislikeItem(
      id: UUID(),
      personId: personID,
      type: kind,
      title: title,
      note: nil,
      createdAt: Date(),
      updatedAt: Date(),
      sortOrder: sortOrder
   )
}

private func storeEncoded<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults) throws {
   defaults.set(try JSONEncoder().encode(value), forKey: key)
}
