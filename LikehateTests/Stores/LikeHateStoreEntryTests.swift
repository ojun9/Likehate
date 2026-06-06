import Foundation
import Testing
@testable import Likehate

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
      #expect(me.profileImageName == DefaultProfileImage.initialMeImage.rawValue)
   }
}
