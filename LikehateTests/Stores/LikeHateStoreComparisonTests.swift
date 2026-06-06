import Foundation
import Testing
@testable import Likehate

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
