import Foundation
import Testing
@testable import Likehate

struct EntryKindTests {
   @Test("入力種別の保存キーは安定している")
   func storageKeysAreStable() {
      #expect(EntryKind.like.storageKey == "OpenLikeKey")
      #expect(EntryKind.hate.storageKey == "OpenHateKey")
   }

   @Test("入力種別の分析名は安定している")
   func analyticsNamesAreStable() {
      #expect(EntryKind.like.analyticsName == "RegiLike")
      #expect(EntryKind.hate.analyticsName == "RegiHate")
   }

   @Test("日本語の入力文言はわたしと嫌い表記を使う")
   func japaneseEntryActionsUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "LikeInputButtonMe", bundle: .main, locale: locale) == "わたしはこれが好き")
      #expect(String(localized: "HateInputButtonMe", bundle: .main, locale: locale) == "これは嫌い")
      #expect(String.localizedStringWithFormat(String(localized: "LikeInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが好き")
      #expect(String.localizedStringWithFormat(String(localized: "HateInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが嫌い")
   }

   @Test("日本語の一覧タイトルはわたしと嫌い表記を使う")
   func japaneseListTitlesUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "MyLikesTitle", bundle: .main, locale: locale) == "わたしの好きなもの")
      #expect(String(localized: "MyHatesTitle", bundle: .main, locale: locale) == "わたしの嫌いなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonLikesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の好きなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonHatesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の嫌いなもの")
   }

   @Test("人物別の入力文言は表示名を使い古い自分表記を使わない")
   func personAwareEntryCopyUsesDisplayNames() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "太郎", isMe: false)

      #expect(EntryKind.like.inputButtonTitle(for: me) == String(localized: "LikeInputButtonMe"))
      #expect(EntryKind.hate.inputButtonTitle(for: me) == String(localized: "HateInputButtonMe"))
      #expect(EntryKind.like.listTitle(for: me) == String(localized: "MyLikesTitle"))
      #expect(EntryKind.hate.listTitle(for: me) == String(localized: "MyHatesTitle"))
      #expect(EntryKind.like.inputButtonTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.hate.inputButtonTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.like.listTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.hate.listTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.like.listTitle(for: me).contains("自分") == false)
      #expect(EntryKind.hate.listTitle(for: me).contains("自分") == false)
   }
}

struct EntryPreviewItemsTests {
   @Test("入力プレビューは現在の並び順の先頭項目を使う")
   func previewsUseFirstItemsFromCurrentOrder() {
      let personID = UUID()
      let items = [
         makeItem(title: "おすし", personID: personID, sortOrder: 0),
         makeItem(title: "カレー", personID: personID, sortOrder: 1),
         makeItem(title: "映画", personID: personID, sortOrder: 2),
         makeItem(title: "散歩", personID: personID, sortOrder: 3)
      ]

      let previewTitles = EntryPreviewItems.items(from: items).map(\.title)

      #expect(previewTitles == ["おすし", "カレー"])
   }

   @Test("入力プレビューは件数制限でき空の制限を拒否する")
   func previewsRespectLimit() {
      let personID = UUID()
      let items = [
         makeItem(title: "おすし", personID: personID, sortOrder: 0),
         makeItem(title: "カレー", personID: personID, sortOrder: 1),
         makeItem(title: "映画", personID: personID, sortOrder: 2)
      ]

      #expect(EntryPreviewItems.maxCount == 2)
      #expect(EntryPreviewItems.items(from: items, limit: 1).map(\.title) == ["おすし"])
      #expect(EntryPreviewItems.items(from: items, limit: 0).isEmpty)
   }
}

struct EntryLottieSelectionTests {
   @Test("入力アニメーション名は入力種別ごとにまとまっている")
   func lottieNamesAreGroupedByEntryKind() {
      #expect(EntryLottieSelection.names(for: .like) == ["MoreHarts", "heart1", "heart2"])
      #expect(EntryLottieSelection.names(for: .hate) == ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"])
      #expect(EntryLottieSelection.fallbackName(for: .like) == "MoreHarts")
      #expect(EntryLottieSelection.fallbackName(for: .hate) == "fish")
   }

   @Test("入力アニメーション選択は可能なら現在のアニメーションを避ける")
   func lottieSelectionAvoidsCurrentAnimation() {
      for name in EntryLottieSelection.names(for: .like) {
         #expect(EntryLottieSelection.randomName(for: .like, excluding: name) != name)
      }

      for name in EntryLottieSelection.names(for: .hate) {
         #expect(EntryLottieSelection.randomName(for: .hate, excluding: name) != name)
      }
   }

   @Test("入力アニメーション選択は各種別の候補内に収まる")
   func lottieSelectionStaysWithinCandidates() {
      let likeNames = EntryLottieSelection.names(for: .like)
      let hateNames = EntryLottieSelection.names(for: .hate)

      #expect(likeNames.contains(EntryLottieSelection.randomName(for: .like, excluding: "missing")))
      #expect(hateNames.contains(EntryLottieSelection.randomName(for: .hate, excluding: "missing")))
   }
}
