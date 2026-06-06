import Foundation
import Testing
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
