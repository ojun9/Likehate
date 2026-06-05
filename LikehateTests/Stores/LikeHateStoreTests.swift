import Foundation
import Testing
import UIKit
@testable import Likehate

@MainActor
struct LikeHateStorePersonTests {
   @Test("新規ストアは保護されたわたしをデフォルト画像付きで1人作る")
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

   @Test("人物追加は名前を整形し選択画像を保存して永続化する")
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

   @Test("空の人物名は人物を変更せず拒否する")
   func blankPersonNamesAreRejected() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let originalPersonIDs = store.persons.map(\.id)

      #expect(store.addPerson(named: "   ", profileImage: .defaultProfileImage7) == nil)
      #expect(store.persons.map(\.id) == originalPersonIDs)
   }

   @Test("新規人物のデフォルト画像は既存人物の画像を避ける")
   func newPersonDefaultProfileImageAvoidsExistingPersonImages() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      store.updatePerson(me.id, name: me.name, profileImage: .defaultProfileImage)
      _ = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage2))
      _ = try #require(store.addPerson(named: "あかり", profileImage: .defaultProfileImage3))

      #expect(store.defaultProfileImageForNewPerson() == .defaultProfileImage4)
   }

   @Test("無料ユーザーはわたしを含めて3人まで登録できる")
   func freeUsersCanRegisterUpToThreePeopleIncludingMe() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let firstFriend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage2))
      let secondFriend = try #require(store.addPerson(named: "あかり", profileImage: .defaultProfileImage3))

      #expect(store.persons.map(\.id) == [me.id, firstFriend.id, secondFriend.id])
      #expect(store.canAddPerson == false)
      #expect(store.addPerson(named: "はると", profileImage: .defaultProfileImage4) == nil)
      #expect(store.persons.count == PremiumAccessPolicy.freePersonLimit)

      store.add("おすし", to: .like, personID: me.id)
      store.add("雨", to: .hate, personID: firstFriend.id)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["おすし"])
      #expect(store.items(for: firstFriend.id, kind: .hate).map(\.title) == ["雨"])
   }

   @Test("プレミアムユーザーは3人を超えて追加できる")
   func premiumUsersCanAddMoreThanThreePeople() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(true, forKey: "PremiumLifetimePurchased")
      })
      defer { context.cleanup() }

      let store = context.store

      _ = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage2))
      _ = try #require(store.addPerson(named: "あかり", profileImage: .defaultProfileImage3))
      let thirdFriend = try #require(store.addPerson(named: "はると", profileImage: .defaultProfileImage4))

      #expect(store.hasPremiumAccess)
      #expect(store.canAddPerson)
      #expect(store.persons.count == PremiumAccessPolicy.freePersonLimit + 1)
      #expect(store.person(for: thirdFriend.id)?.displayName == "はると")
   }

   @Test("既存の広告非表示購入はプレミアムアクセスとして扱う")
   func existingAdRemovalPurchaseIsTreatedAsPremiumAccess() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(true, forKey: "BuyRemoveAd")
      })
      defer { context.cleanup() }

      let store = context.store

      #expect(store.didBuyRemoveAd)
      #expect(store.didBuyPremium)
      #expect(store.appSettings.adsRemoved)
      #expect(store.appSettings.isPremium)
      #expect(store.hasPremiumAccess)

      _ = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage2))
      _ = try #require(store.addPerson(named: "あかり", profileImage: .defaultProfileImage3))
      _ = try #require(store.addPerson(named: "はると", profileImage: .defaultProfileImage4))
      #expect(store.persons.count == PremiumAccessPolicy.freePersonLimit + 1)
   }

   @Test("プレミアム商品情報はレベニューキャットの商品価格を読み込む")
   func premiumProductInfoLoadsRevenueCatProductPrice() async throws {
      let service = PremiumPurchaseServiceStub()
      service.currentPremiumPackageResult = .success(PremiumPackage(localizedPrice: "¥600"))
      let context = try StoreTestContext(premiumPurchaseService: service)
      defer { context.cleanup() }

      context.store.loadPremiumProductInfo()

      try await waitUntil { context.store.premiumProductPrice == "¥600" }
      #expect(service.didRequestCurrentPremiumPackage)
   }

   @Test("プレミアム購入はレベニューキャットを使いプレミアムアクセスを解除する")
   func premiumPurchaseUsesRevenueCatAndUnlocksPremiumAccess() async throws {
      let service = PremiumPurchaseServiceStub()
      service.currentPremiumPackageResult = .success(PremiumPackage(localizedPrice: "¥600"))
      service.purchaseResult = .success(.active)
      let context = try StoreTestContext(premiumPurchaseService: service)
      defer { context.cleanup() }

      context.store.purchasePremium()

      try await waitUntil { context.store.isPurchasing == false && context.store.didBuyPremium }
      #expect(service.didPurchase)
      #expect(context.store.didBuyRemoveAd == false)
      #expect(context.store.appSettings.isPremium)
      #expect(context.store.purchaseMessage?.title == String(localized: "PremiumPurchaseSucceededTitle"))
   }

   @Test("キャンセルしたプレミアム購入はエラー表示も解除もしない")
   func cancelledPremiumPurchaseDoesNotShowErrorOrUnlock() async throws {
      let service = PremiumPurchaseServiceStub()
      service.currentPremiumPackageResult = .success(PremiumPackage(localizedPrice: "¥600"))
      service.purchaseResult = .success(.userCancelled)
      let context = try StoreTestContext(premiumPurchaseService: service)
      defer { context.cleanup() }

      context.store.purchasePremium()

      try await waitUntil { context.store.isPurchasing == false && service.didPurchase }
      #expect(context.store.didBuyPremium == false)
      #expect(context.store.purchaseMessage == nil)
   }

   @Test("有効なレベニューキャット権限がない復元は無料状態のままにする")
   func restoreWithoutActiveRevenueCatEntitlementStaysFree() async throws {
      let service = PremiumPurchaseServiceStub()
      service.restoreResult = .success(.missingEntitlement)
      let context = try StoreTestContext(premiumPurchaseService: service)
      defer { context.cleanup() }

      context.store.restorePurchases()

      try await waitUntil { context.store.isRestoring == false && service.didRestore }
      #expect(context.store.hasPremiumAccess == false)
      #expect(context.store.purchaseMessage?.message == String(localized: "RestorePurchaseEmptyMessage"))
   }

   @Test("プレミアム更新はレベニューキャットの有効権限を反映する")
   func premiumRefreshAppliesRevenueCatActiveEntitlement() async throws {
      let service = PremiumPurchaseServiceStub()
      service.currentEntitlementStateResult = .success(.active)
      let context = try StoreTestContext(premiumPurchaseService: service)
      defer { context.cleanup() }

      context.store.refreshPremiumStatus()

      try await waitUntil { context.store.hasPremiumAccess }
      #expect(service.didRequestCurrentEntitlementState)
   }

   @Test("人物追加と更新は名前を40文字に制限する")
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

   @Test("わたしの更新は変更した名前を保存して表示する")
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

   @Test("他人の更新は保存名と表示名を変更する")
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

   @Test("空の人物更新はプロフィール画像を変えず拒否する")
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

   @Test("人物削除はその人の項目を消しわたしは保護する")
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

   @Test("保存済み人物は正規化されわたし1人を保ち孤立項目を除外する")
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

   @Test("空の保存済み人物はわたし1人に戻り孤立項目を落とす")
   func emptyStoredPeopleNormalizeToMeOnly() throws {
      let orphanID = UUID()
      let storedItems = [
         makeStoredItem(personID: orphanID, kind: .like, title: "消える", sortOrder: 0)
      ]
      let context = try StoreTestContext(initialValues: { defaults in
         try? storeEncoded([Person](), forKey: "LikehatePersonsV1", defaults: defaults)
         try? storeEncoded(storedItems, forKey: "LikehateItemsV1", defaults: defaults)
      })
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      #expect(store.persons.count == 1)
      #expect(me.isMe)
      #expect(me.displayName == String(localized: "DefaultMeName"))
      #expect(store.entries.isEmpty)
   }

   @Test("わたしがいない保存済み人物は並び順先頭をわたしに昇格する")
   func storedPeopleWithoutMePromoteFirstSortedPerson() throws {
      let firstID = UUID()
      let secondID = UUID()
      let now = Date()
      let storedPersons = [
         makeStoredPerson(id: secondID, name: "太郎", profileImageName: DefaultProfileImage.defaultProfileImage4.rawValue, isMe: false, createdAt: now.addingTimeInterval(10), sortOrder: 1),
         makeStoredPerson(id: firstID, name: "あかり", profileImageName: DefaultProfileImage.defaultProfileImage5.rawValue, isMe: false, createdAt: now, sortOrder: 0)
      ]
      let storedItems = [
         makeStoredItem(personID: firstID, kind: .like, title: "おすし", sortOrder: 0),
         makeStoredItem(personID: secondID, kind: .hate, title: "雨", sortOrder: 0)
      ]
      let context = try StoreTestContext(initialValues: { defaults in
         try? storeEncoded(storedPersons, forKey: "LikehatePersonsV1", defaults: defaults)
         try? storeEncoded(storedItems, forKey: "LikehateItemsV1", defaults: defaults)
      })
      defer { context.cleanup() }

      let store = context.store
      let promotedPerson = try #require(store.person(for: firstID))
      let otherPerson = try #require(store.person(for: secondID))

      #expect(store.persons.map(\.id) == [firstID, secondID])
      #expect(promotedPerson.isMe)
      #expect(promotedPerson.name == String(localized: "DefaultMeName"))
      #expect(otherPerson.isMe == false)
      #expect(store.entries.count == 2)
   }
}

@MainActor
struct LikeHateStoreEntryTests {
   @Test("項目は空白整形と空文字拒否と更新移動削除を行う")
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

   @Test("項目プレビューは並び替え後の一覧順に従う")
   func entryPreviewFollowsReorderedListOrder() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("おすし", to: .like, personID: me.id)
      store.add("カレー", to: .like, personID: me.id)
      store.add("映画", to: .like, personID: me.id)
      store.add("散歩", to: .like, personID: me.id)

      #expect(EntryPreviewItems.items(from: store.items(for: me.id, kind: .like)).map(\.title) == ["おすし", "カレー"])

      store.move(from: IndexSet(integer: 3), to: 0, in: .like, personID: me.id)

      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["散歩", "おすし", "カレー", "映画"])
      #expect(EntryPreviewItems.items(from: store.items(for: me.id, kind: .like)).map(\.title) == ["散歩", "おすし"])
   }

   @Test("項目は存在しない人物や項目更新を変更なしで拒否する")
   func invalidEntryTargetsAndUpdatesDoNotMutateEntries() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("おすし", to: .like, personID: UUID())
      #expect(store.entries.isEmpty)

      store.add("おすし", to: .like, personID: me.id)
      #expect(store.updateItem(UUID(), title: "カレー") == false)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["おすし"])
   }

   @Test("更新した項目タイトルは整形され再読み込み後も残る")
   func updatedEntryTitlesPersistTrimmed() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      store.add("おすし", to: .like, personID: me.id)
      let item = try #require(store.items(for: me.id, kind: .like).first)

      #expect(store.updateItem(item.id, title: "  焼き魚  "))

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.items(for: me.id, kind: .like).map(\.title) == ["焼き魚"])
   }

   @Test("移動した項目は再読み込み後も新しい順序を保つ")
   func movedEntriesPersistOrderAfterReload() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("おすし", to: .like, personID: me.id)
      store.add("カレー", to: .like, personID: me.id)
      store.add("映画", to: .like, personID: me.id)

      store.move(from: IndexSet(integer: 2), to: 0, in: .like, personID: me.id)

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      let reloadedItems = reloadedStore.items(for: me.id, kind: .like)

      #expect(reloadedItems.map(\.title) == ["映画", "おすし", "カレー"])
      #expect(reloadedItems.map(\.sortOrder) == [0, 1, 2])
   }

   @Test("同じ並び順の保存済み項目は作成日にフォールバックする")
   func storedEntriesWithMatchingSortOrderUseCreatedAtOrder() throws {
      let personID = UUID()
      let now = Date(timeIntervalSince1970: 1_000)
      let storedPersons = [
         makeStoredPerson(id: personID, name: "自分", profileImageName: DefaultProfileImage.defaultProfileImage.rawValue, isMe: true, createdAt: now, sortOrder: 0)
      ]
      let storedItems = [
         makeStoredItem(personID: personID, kind: .like, title: "あと", sortOrder: 0, createdAt: now.addingTimeInterval(30)),
         makeStoredItem(personID: personID, kind: .like, title: "まえ", sortOrder: 0, createdAt: now),
         makeStoredItem(personID: personID, kind: .like, title: "まんなか", sortOrder: 0, createdAt: now.addingTimeInterval(10))
      ]
      let context = try StoreTestContext(initialValues: { defaults in
         try? storeEncoded(storedPersons, forKey: "LikehatePersonsV1", defaults: defaults)
         try? storeEncoded(storedItems, forKey: "LikehateItemsV1", defaults: defaults)
      })
      defer { context.cleanup() }

      let store = context.store

      #expect(store.items(for: personID, kind: .like).map(\.title) == ["まえ", "まんなか", "あと"])
   }

   @Test("項目削除は範囲外の位置指定を無視し有効削除後に採番し直す")
   func deletingEntriesIgnoresOutOfRangeOffsetsAndRenumbers() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)

      store.add("おすし", to: .like, personID: me.id)
      store.add("カレー", to: .like, personID: me.id)
      store.add("映画", to: .like, personID: me.id)
      store.add("雨", to: .hate, personID: me.id)

      store.delete(at: IndexSet(integer: 99), from: .like, personID: me.id)
      #expect(store.items(for: me.id, kind: .like).map(\.title) == ["おすし", "カレー", "映画"])
      #expect(store.items(for: me.id, kind: .hate).map(\.title) == ["雨"])

      store.delete(at: IndexSet(integer: 1), from: .like, personID: me.id)
      let reloadedStore = LikeHateStore(defaults: context.defaults)
      let reloadedLikes = reloadedStore.items(for: me.id, kind: .like)

      #expect(reloadedLikes.map(\.title) == ["おすし", "映画"])
      #expect(reloadedLikes.map(\.sortOrder) == [0, 1])
      #expect(reloadedStore.items(for: me.id, kind: .hate).map(\.title) == ["雨"])
   }

   @Test("旧好き嫌い配列はわたしの項目へ移行される")
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
   @Test("写真データは正方形画像サムネイルへ変換される")
   func photoDataIsConvertedIntoSquareThumbnail() throws {
      let sourceData = try TestImageFactory.jpegData(size: CGSize(width: 80, height: 40), color: .systemPink)
      let thumbnailData = try #require(LikeHateStore.thumbnailPhotoData(from: sourceData))
      let thumbnail = try #require(UIImage(data: thumbnailData))

      #expect(Int(thumbnail.size.width) == 512)
      #expect(Int(thumbnail.size.height) == 512)
   }

   @Test("不正な写真データは拒否される")
   func invalidPhotoDataIsRejected() {
      #expect(LikeHateStore.thumbnailPhotoData(from: Data("not image".utf8)) == nil)
   }

   @Test("人物写真は保存読込削除でき人物削除時にも消える")
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

   @Test("プリセット画像更新は既存写真を削除する")
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

   @Test("存在しない写真ファイルは無視される")
   func missingPhotoFileIsIgnored() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      var person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3))
      person.photoFileName = "person_missing.jpg"

      #expect(store.photoURL(for: person) == nil)
      #expect(store.photoImage(for: person) == nil)
   }
}

@MainActor
struct LikeHateStoreComparisonTests {
   @Test("比較セクションは共通項目と人物別項目を分類する")
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

   @Test("比較セクションは大文字小文字を無視して重複排除し先頭タイトルを保つ")
   func comparisonSectionsDeduplicateCaseInsensitively() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage5))

      store.add("Tea", to: .like, personID: me.id)
      store.add("tea", to: .like, personID: me.id)
      store.add("Coffee", to: .like, personID: me.id)
      store.add("TEA", to: .like, personID: friend.id)
      store.add("Cake", to: .like, personID: friend.id)

      store.add("Rain", to: .hate, personID: me.id)
      store.add("rain", to: .hate, personID: me.id)
      store.add("RAIN", to: .hate, personID: friend.id)
      store.add("Smoke", to: .hate, personID: friend.id)

      let sections = Dictionary(uniqueKeysWithValues: store
         .comparisonSections(firstPersonID: me.id, secondPersonID: friend.id)
         .map { ($0.category, $0.titles) })

      #expect(sections[.commonLike] == ["Tea"])
      #expect(sections[.firstOnlyLike] == ["Coffee"])
      #expect(sections[.secondOnlyLike] == ["Cake"])
      #expect(sections[.commonHate] == ["Rain"])
      #expect(sections[.firstOnlyHate] == [])
      #expect(sections[.secondOnlyHate] == ["Smoke"])
   }
}

@MainActor
struct LikeHateStoreSettingsTests {
   @Test("デフォルト設定は控えめで読みやすい")
   func defaultSettings() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let settings = context.store.appSettings

      #expect(settings.animationEnabled)
      #expect(settings.vibrationEnabled)
      #expect(settings.adsRemoved == false)
      #expect(settings.isPremium == false)
      #expect(settings.textSize == .standard)
   }

   @Test("不正な保存文字サイズは標準に戻る")
   func invalidStoredTextSizeFallsBackToStandard() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set("giant", forKey: "AppTextSize")
      })
      defer { context.cleanup() }

      #expect(context.store.textSize == .standard)
   }

   @Test("文字サイズはユーザーデフォルトとアプリ設定に永続化される")
   func textSizePersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.textSize = .extraLarge

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.textSize == .extraLarge)
      #expect(reloadedStore.appSettings.textSize == .extraLarge)
   }

   @Test("アニメーション設定はユーザーデフォルトに永続化される")
   func animationSettingPersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.animationEnabled = false

      let reloadedStore = LikeHateStore(defaults: context.defaults)

      #expect(reloadedStore.animationEnabled == false)
      #expect(reloadedStore.appSettings.animationEnabled == false)
   }

   @Test("アプリ設定は永続化された触覚と広告フラグを読む")
   func appSettingsReadPersistedHapticsAndAdFlags() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(false, forKey: "HapticsEnabled")
         defaults.set(true, forKey: "BuyRemoveAd")
      })
      defer { context.cleanup() }

      let settings = context.store.appSettings

      #expect(settings.vibrationEnabled == false)
      #expect(settings.adsRemoved)
      #expect(settings.isPremium)
   }

   #if DEBUG
   @Test("アップストアスクショモードはサンプルデータへ差し替え元データを復元する")
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
      let sampleCounts = [
         store.items(for: sampleMe.id, kind: .like).count,
         store.items(for: sampleMe.id, kind: .hate).count,
         store.items(for: sampleAkari.id, kind: .like).count,
         store.items(for: sampleAkari.id, kind: .hate).count,
         store.items(for: sampleHaruto.id, kind: .like).count,
         store.items(for: sampleHaruto.id, kind: .hate).count
      ]
      #expect(sampleCounts == [23, 16, 29, 14, 21, 27])
      #expect(sampleCounts.allSatisfy { (14...30).contains($0) })
      #expect(sampleCounts.min() == 14)
      #expect(sampleCounts.max() == 29)
      #expect(Set(sampleCounts).count == sampleCounts.count)
      #expect(store.entries.count == sampleCounts.reduce(0, +))
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

   @Test("アップストアスクショモードはストア再読込後も復元できる")
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

   @Test("全削除は項目をリセットしわたしだけを作り直す")
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

   @Test("全削除は旧項目配列も消す")
   func deleteAllClearsLegacyEntryArrays() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(["おすし"], forKey: EntryKind.like.storageKey)
         defaults.set(["雨"], forKey: EntryKind.hate.storageKey)
      })
      defer { context.cleanup() }

      let store = context.store
      #expect(context.defaults.stringArray(forKey: EntryKind.like.storageKey) == ["おすし"])
      #expect(context.defaults.stringArray(forKey: EntryKind.hate.storageKey) == ["雨"])

      store.deleteAll()

      #expect(context.defaults.stringArray(forKey: EntryKind.like.storageKey) == nil)
      #expect(context.defaults.stringArray(forKey: EntryKind.hate.storageKey) == nil)
   }
}

@MainActor
private struct StoreTestContext {
   let suiteName: String
   let defaults: UserDefaults
   let store: LikeHateStore

   init(initialValues: ((UserDefaults) -> Void)? = nil, premiumPurchaseService: PremiumPurchaseServicing? = nil) throws {
      suiteName = "LikehateTests-\(UUID().uuidString)"
      guard let defaults = UserDefaults(suiteName: suiteName) else {
         throw StoreTestError.userDefaultsUnavailable
      }
      defaults.removePersistentDomain(forName: suiteName)
      initialValues?(defaults)

      self.defaults = defaults
      if let premiumPurchaseService {
         store = LikeHateStore(defaults: defaults, premiumPurchaseService: premiumPurchaseService)
      } else {
         store = LikeHateStore(defaults: defaults)
      }
   }

   func cleanup() {
      defaults.removePersistentDomain(forName: suiteName)
   }
}

@MainActor
private final class PremiumPurchaseServiceStub: PremiumPurchaseServicing {
   var currentEntitlementStateResult: Result<PremiumEntitlementState, Error> = .success(.inactive)
   var currentPremiumPackageResult: Result<PremiumPackage?, Error> = .success(nil)
   var purchaseResult: Result<PremiumPurchaseResult, Error> = .success(.inactive)
   var restoreResult: Result<PremiumPurchaseResult, Error> = .success(.inactive)

   private(set) var didRequestCurrentEntitlementState = false
   private(set) var didRequestCurrentPremiumPackage = false
   private(set) var didPurchase = false
   private(set) var didRestore = false

   func currentEntitlementState() async throws -> PremiumEntitlementState {
      didRequestCurrentEntitlementState = true
      return try currentEntitlementStateResult.get()
   }

   func currentPremiumPackage() async throws -> PremiumPackage? {
      didRequestCurrentPremiumPackage = true
      return try currentPremiumPackageResult.get()
   }

   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult {
      didPurchase = true
      return try purchaseResult.get()
   }

   func restorePurchases() async throws -> PremiumPurchaseResult {
      didRestore = true
      return try restoreResult.get()
   }
}

@MainActor
private func waitUntil(_ predicate: @escaping @MainActor () -> Bool) async throws {
   for _ in 0..<100 {
      if predicate() {
         return
      }
      try await Task.sleep(nanoseconds: 1_000_000)
   }
   Issue.record("Timed out waiting for async store work")
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
   sortOrder: Int,
   createdAt: Date = Date()
) -> LikeDislikeItem {
   LikeDislikeItem(
      id: UUID(),
      personId: personID,
      type: kind,
      title: title,
      note: nil,
      createdAt: createdAt,
      updatedAt: createdAt,
      sortOrder: sortOrder
   )
}

private func storeEncoded<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults) throws {
   defaults.set(try JSONEncoder().encode(value), forKey: key)
}
