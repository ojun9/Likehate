import Foundation
import Testing
@testable import Likehate

struct LocalizationTests {
   @Test("日本語の一人称ローカライズはわたしになる")
   func japaneseFirstPersonLocalizationIsWatashi() {
      let japaneseMeName = String(localized: "DefaultMeName", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(japaneseMeName == "わたし")
   }

   @Test("日本語の人物フォーム文言はメモ帳らしいトーンにする")
   func japanesePersonFormCopyMatchesMemoTone() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "AddPersonTitle", bundle: .main, locale: locale) == "人を追加")
      #expect(String(localized: "AddPersonHelpText", bundle: .main, locale: locale) == "好きなものや苦手なものを、あとで思い出せるように残しておけます。")
      #expect(String(localized: "PersonNamePlaceholder", bundle: .main, locale: locale) == "呼び方を書く")
      #expect(String(localized: "AddPersonSaveButton", bundle: .main, locale: locale) == "追加")
      #expect(String(localized: "ProfileImageSectionTitle", bundle: .main, locale: locale) == "プリセット")
      #expect(String.localizedStringWithFormat(String(localized: "ProfileImageOptionFormat", bundle: .main, locale: locale), 3) == "プリセット 3")
      #expect(String(localized: "SavePersonChangesButton", bundle: .main, locale: locale) == "保存")
      #expect(String(localized: "EditPersonHelpText", bundle: .main, locale: locale) == "呼び方やアイコンを変えられます。")
      #expect(String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat", bundle: .main, locale: locale), "あかり") == "あかりのこと")
      #expect(String(localized: "DeletePersonConfirmationTitle", bundle: .main, locale: locale) == "この人を削除しますか？")
      #expect(String(localized: "DeletePersonConfirmationMessage", bundle: .main, locale: locale) == "残していた好きなものや苦手なものも削除されます。")
      #expect(String(localized: "DeletePersonConfirmButton", bundle: .main, locale: locale) == "削除する")
   }

   @Test("英語の人物フォーム文言はユーザー向け文字列に解決される")
   func englishPersonFormCopyResolves() {
      let locale = Locale(identifier: "en")
      let keys = [
         "AddPersonTitle",
         "AddPersonHelpText",
         "PersonNamePlaceholder",
         "AddPersonSaveButton",
         "ProfileImageSectionTitle",
         "ProfileImageOptionFormat",
         "SavePersonChangesButton",
         "EditPersonHelpText",
         "DeletePersonConfirmationTitle",
         "DeletePersonConfirmationMessage",
         "DeletePersonConfirmButton"
      ]

      for key in keys {
         let value = String(localized: String.LocalizationValue(key), bundle: .main, locale: locale)
         #expect(value.isEmpty == false)
         #expect(value != key)
      }

      let title = String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat", bundle: .main, locale: locale), "Akari")
      #expect(title.contains("Akari"))
      #expect(title != "EditPersonTitleFormat")
   }

   @Test("廃止済みの人物編集文言は古い無機質な表記に解決されない")
   func deprecatedPersonEditCopyAvoidsMechanicalWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "EditPersonButton", bundle: .main, locale: locale) != "人を編集")
      #expect(String(localized: "EditPersonTitle", bundle: .main, locale: locale) != "人を編集")
   }

   @Test("日本語の比較文言は苦手ではなく嫌い表記を使う")
   func japaneseComparisonCopyUsesDislike() {
      let firstOnlyHate = String(localized: "ComparisonFirstOnlyHateFormat", bundle: .main, locale: Locale(identifier: "ja"))
      let secondOnlyHate = String(localized: "ComparisonSecondOnlyHateFormat", bundle: .main, locale: Locale(identifier: "ja"))
      let commonHate = String(localized: "ComparisonCommonHate", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(firstOnlyHate.contains("嫌い"))
      #expect(secondOnlyHate.contains("嫌い"))
      #expect(commonHate.contains("嫌い"))
      #expect(firstOnlyHate.contains("苦手") == false)
      #expect(secondOnlyHate.contains("苦手") == false)
      #expect(commonHate.contains("苦手") == false)
   }

   @Test("日本語の共通比較文言はどっちも表記を使う")
   func japaneseCommonComparisonCopyUsesBothWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "ComparisonCommonLike", bundle: .main, locale: locale) == "どっちも好き")
      #expect(String(localized: "ComparisonCommonHate", bundle: .main, locale: locale) == "どっちも嫌い")
      #expect(String(localized: "ComparisonEmptyCommonLike", bundle: .main, locale: locale) == "どっちも好きなものはまだありません")
      #expect(String(localized: "ComparisonEmptyCommonHate", bundle: .main, locale: locale) == "どっちも嫌いなものはまだありません")
   }

   @Test("日本語の比較差分セクションはふたりの違い表記を使う")
   func japaneseComparisonDifferenceSectionUsesRelationshipWording() {
      let title = String(localized: "ComparisonDifferencesTitle", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(title == "ふたりの違い")
      #expect(title != "違いを見る")
   }

   @Test("デバッグメニューのローカライズキーが解決される")
   func debugMenuLocalizationKeysResolve() {
      let keys = [
         "DebugSectionTitle",
         "AppStoreScreenshotModeTitle",
         "AppStoreScreenshotModeSubtitle",
         "RevenueCatDebugTitle",
         "RevenueCatDebugSubtitle"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
      }
   }

   @Test("日本語の買い切りプレミアム文言は買い切りと無料上限を説明する")
   func japanesePremiumCopyExplainsOneTimePurchaseAndFreeLimit() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "PremiumBadge", bundle: .main, locale: locale) == "買い切り")
      #expect(String(localized: "PremiumTitle", bundle: .main, locale: locale) == "買い切りプレミアム")
      #expect(String(localized: "PremiumHeroTitle", bundle: .main, locale: locale) == "もっと大切な人を追加できます")
      #expect(String(localized: "PremiumFreeLimitMessage", bundle: .main, locale: locale) == "無料版では、あなたを含めて3人まで登録できます。")
      #expect(String(localized: "PremiumUpgradeMessage", bundle: .main, locale: locale) == "買い切りプレミアムにすると、4人以上の好き嫌いも残せて、広告も非表示になります。")
      #expect(String(localized: "PremiumOneTimeNote", bundle: .main, locale: locale) == "月額ではありません。一度の購入で使えます。")
      #expect(String(localized: "PremiumComparisonTitle", bundle: .main, locale: locale) == "できることが広がります")
      #expect(String(localized: "PremiumFreePlanTitle", bundle: .main, locale: locale) == "無料版")
      #expect(String(localized: "PremiumFreePlanBadge", bundle: .main, locale: locale) == "現在")
      #expect(String(localized: "PremiumFreePlanMessage", bundle: .main, locale: locale) == "3人まで登録できます。一覧画面には広告が表示されます。")
      #expect(String(localized: "PremiumPaidPlanTitle", bundle: .main, locale: locale) == "買い切りプレミアム")
      #expect(String(localized: "PremiumPaidPlanMessage", bundle: .main, locale: locale) == "4人以上追加できて、一覧画面の広告も非表示になります。")
      #expect(String(localized: "PremiumPriceLoading", bundle: .main, locale: locale) == "価格を読み込み中")
      #expect(String(localized: "PremiumPurchaseButton", bundle: .main, locale: locale) == "買い切りプレミアムを購入")
      #expect(String(format: String(localized: "PremiumPurchaseButtonWithPriceFormat", bundle: .main, locale: locale), "¥800") == "買い切りプレミアムを購入（¥800）")
      #expect(String(localized: "PremiumRestoreButton", bundle: .main, locale: locale) == "購入を復元")
      #expect(String(localized: "PremiumCloseButton", bundle: .main, locale: locale) == "あとで")
      #expect(String(localized: "PremiumSettingsSubtitle", bundle: .main, locale: locale) == "人数制限解除・広告非表示")
      #expect(String(localized: "PremiumPurchasedStatus", bundle: .main, locale: locale) == "購入済み")
   }

   @Test("プレミアムと復元のローカライズキーが解決される")
   func premiumAndRestoreLocalizationKeysResolve() {
      let keys = [
         "PremiumBadge",
         "PremiumBenefitLifetime",
         "PremiumBenefitNoAds",
         "PremiumBenefitPeople",
         "PremiumComparisonTitle",
         "PremiumFreePlanBadge",
         "PremiumFreePlanMessage",
         "PremiumFreePlanTitle",
         "PremiumPaidPlanMessage",
         "PremiumPaidPlanTitle",
         "PremiumPriceLoading",
         "PremiumPurchaseButtonWithPriceFormat",
         "PremiumPurchaseDeferredMessage",
         "PremiumPurchaseDeferredTitle",
         "PremiumPurchaseFailedTitle",
         "PremiumPurchaseSucceededMessage",
         "PremiumPurchaseSucceededTitle",
         "PremiumPurchaseUnavailableMessage",
         "RestorePurchaseEmptyMessage",
         "RestorePurchaseEmptyTitle",
         "RestorePurchaseFailedTitle",
         "RestorePurchaseSucceededMessage",
         "RestorePurchaseSucceededTitle"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
      }
   }

   @Test("比較空状態のローカライズキーが解決される")
   func comparisonEmptyStateLocalizationKeysResolve() {
      let keys = [
         "ComparisonEmptyCommonHate",
         "ComparisonEmptyCommonHateMessage",
         "ComparisonEmptyCommonLike",
         "ComparisonEmptyCommonLikeMessage",
         "ComparisonEmptyFirstOnlyHateMessage",
         "ComparisonEmptyFirstOnlyLikeMessage",
         "ComparisonEmptySecondOnlyHateMessageFormat",
         "ComparisonEmptySecondOnlyLikeMessageFormat"
      ]

      for key in keys {
         let value = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         #expect(value.isEmpty == false)
         #expect(value != key)
      }
   }

   @Test("入力一覧空状態のローカライズキーが解決される")
   func entryEmptyListLocalizationKeysResolve() {
      let keys = [
         "EmptyLikesTitle",
         "EmptyLikesMessage",
         "EmptyHatesTitle",
         "EmptyHatesMessage"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
      }
   }
}
