import Foundation
import Testing
@testable import Likehate

struct AdDisplayPolicyTests {
   @Test("一覧広告は項目がある無料ユーザーだけに表示される")
   func listAdsShowOnlyForFreeUsersWithItems() {
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: true))
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: false) == false)
   }

   @Test("一覧広告は広告非表示購入済みとプレミアムユーザーには表示されない")
   func listAdsAreHiddenForAdRemovedAndPremiumUsers() {
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: false).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: true).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: true).showsListAd(hasItems: true) == false)
   }
}

struct PremiumAccessPolicyTests {
   @Test("無料人物上限はわたしを含めて3人で止まる")
   func freePersonLimitIncludesMeAndStopsAtThreePeople() {
      #expect(PremiumAccessPolicy.freePersonLimit == 3)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 1).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 2).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 3).canAddPerson == false)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 4).canAddPerson == false)
   }

   @Test("プレミアムと旧広告非表示購入はいずれも人物上限を解除する")
   func premiumAndLegacyAdRemovalBothUnlockPersonLimit() {
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: false, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: true, personCount: 8).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).hasPremiumAccess)
   }
}

struct AppTextSizeTests {
   @Test("文字サイズは小さい順から大きい順に並ぶ")
   func textSizesAreOrderedFromSmallestToLargest() {
      #expect(AppTextSize.allCases == [.extraSmall, .small, .standard, .large, .extraLarge])
   }

   @Test("文字サイズタイトルは全選択肢を網羅する")
   func textSizeTitlesExistForEveryCase() {
      #expect(AppTextSize.allCases.count == 5)

      for textSize in AppTextSize.allCases {
         #expect(String(describing: textSize.title).isEmpty == false)
      }
   }

   @Test("ホームのアバターサイズはアプリ文字サイズに追従する")
   func homeAvatarSizeScalesWithTextSize() {
      let extraSmall = AppLayoutMetrics(textSize: .extraSmall).homePersonAvatarSize
      let standard = AppLayoutMetrics(textSize: .standard).homePersonAvatarSize
      let extraLarge = AppLayoutMetrics(textSize: .extraLarge).homePersonAvatarSize

      #expect(extraSmall < standard)
      #expect(standard < extraLarge)
   }

   @Test("文字サイズの段階移動は選択可能範囲で止まる")
   func textSizeAdvancementClampsAtBounds() {
      #expect(AppTextSize.extraSmall.advanced(by: 2) == .standard)
      #expect(AppTextSize.small.advanced(by: 2) == .large)
      #expect(AppTextSize.standard.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.large.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.extraSmall.advanced(by: -2) == .extraSmall)
   }

   @Test("レイアウト寸法は選択した文字サイズに合わせて広がる")
   func layoutMetricsExpandWithSelectedTextSize() {
      let metrics = AppTextSize.allCases.map(AppLayoutMetrics.init(textSize:))

      #expect(metrics.map(\.screenPadding) == [16, 18, 20, 22, 22])
      #expect(metrics.map(\.cardPadding) == [14, 16, 18, 20, 22])
      #expect(metrics.map(\.cardSpacing) == [10, 12, 14, 16, 18])
      #expect(metrics.map(\.sectionSpacing) == [20, 22, 26, 30, 34])
      #expect(metrics.map(\.rowMinHeight) == [48, 52, 58, 64, 70])
      #expect(metrics.map(\.personCardMinHeight) == [104, 112, 124, 136, 148])
      #expect(metrics.map(\.homePersonAvatarSize) == [78, 84, 93, 102, 111])
   }
}
