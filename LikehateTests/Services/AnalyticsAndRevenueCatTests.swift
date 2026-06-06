import Foundation
import FirebaseAnalytics
import Testing
@testable import Likehate

struct RevenueCatContractsTests {
   @Test("レベニューキャット契約は設定済みの公開アイオーエス開発キットキーを使う")
   func revenueCatContractUsesConfiguredPublicIOSSDKKey() {
      #expect(LikehateRevenueCatContracts.publicSDKKey == "appl_KjaunKCKXyQMEbmdzqjXhbbiEkG")
      #expect(LikehateRevenueCatContracts.premiumProductID == "NO_ADS_LIKEHATE")
      #expect(LikehateRevenueCatContracts.premiumEntitlementID == "premium")
   }
}

struct FAEventTests {
   @Test("デバッグビルドではFirebase Analyticsへ送信しない")
   func debugBuildDoesNotSendFirebaseAnalyticsEvents() {
      #if DEBUG
      #expect(FAAnalytics.sendsFirebaseEvents == false)
      #else
      #expect(FAAnalytics.sendsFirebaseEvents)
      #endif
   }

   @Test("画面表示イベントはFirebase標準のscreen_viewを使う")
   func screenViewUsesFirebaseScreenEvent() {
      let event = FAEvent.screenView(.premium, parameters: [.source: "settings"])

      #expect(event.name == AnalyticsEventScreenView)
      #expect(event.parameters?[AnalyticsParameterScreenName] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?[AnalyticsParameterScreenClass] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?["source"] as? String == "settings")
   }

   @Test("通常イベントは定義済みイベント名と型付きパラメータをFirebase用に変換する")
   func trackEventUsesDefinedNameAndTypedParameters() {
      let event = FAEvent.track(.personAdded, parameters: [
         .source: FAScreen.home.rawValue,
         .personCount: 3,
         .personName: "あかり",
         .isMe: false,
         .profileImage: "defaultProfileImage04",
         .profileImageSource: FAProfileImageSource.selectedPreset.rawValue,
         .entryText: "おすし"
      ])

      #expect(event.name == "person_added")
      #expect(event.parameters?["source"] as? String == "home")
      #expect(event.parameters?["person_count"] as? Int == 3)
      #expect(event.parameters?["person_name"] as? String == "あかり")
      #expect(event.parameters?["is_me"] as? Bool == false)
      #expect(event.parameters?["profile_image"] as? String == "defaultProfileImage04")
      #expect(event.parameters?["profile_image_source"] as? String == "selected_preset")
      #expect(event.parameters?["entry_text"] as? String == "おすし")
   }

   @Test("通常イベントはパラメータなしでも送信できる")
   func trackEventAllowsNoParameters() {
      let event = FAEvent.track(.premiumRestoreStarted, parameters: nil)

      #expect(event.name == "premium_restore_started")
      #expect(event.parameters == nil)
   }

   @Test("画面名は重複なくFirebaseに送れる値で一覧化されている")
   func screenNamesAreListedAndUnique() {
      let screens = FAScreen.allCases.map(\.rawValue)

      #expect(screens.count == Set(screens).count)
      #expect(screens.allSatisfy { $0.isEmpty == false })
      #expect(screens.contains("home"))
      #expect(screens.contains("premium"))
      #expect(screens.contains("comparison_category_detail"))
   }

   @Test("入力本文パラメータは空白を落として長すぎる値を制限する")
   func entryTextParameterTrimsAndLimitsLongValues() throws {
      let longText = String(repeating: "あ", count: FAEntryTextParameter.maxLength + 5)
      let trimmed = try #require(FAEntryTextParameter.value(from: "  おすし  \n"))
      let limited = try #require(FAEntryTextParameter.value(from: longText))

      #expect(trimmed == "おすし")
      #expect(limited.count == FAEntryTextParameter.maxLength)
      #expect(FAEntryTextParameter.value(from: "   \n") == nil)
   }

   @Test("人物名パラメータは保存ルールと同じ整形を使う")
   func personNameParameterUsesPersonNameRules() throws {
      let longName = String(repeating: "あ", count: PersonNameRules.maxLength + 5)
      let trimmed = try #require(FAPersonNameParameter.value(from: "  あかり  \n"))
      let limited = try #require(FAPersonNameParameter.value(from: longName))

      #expect(FAPersonNameParameter.maxLength == PersonNameRules.maxLength)
      #expect(trimmed == "あかり")
      #expect(limited.count == PersonNameRules.maxLength)
      #expect(FAPersonNameParameter.value(from: "   \n") == nil)
   }

   @Test("プロフィール画像の由来は分析用の値として一覧化されている")
   func profileImageSourcesAreListedAndUnique() {
      let sources = FAProfileImageSource.allCases.map(\.rawValue)

      #expect(sources.count == Set(sources).count)
      #expect(sources == [
         "random_preset",
         "selected_preset",
         "selected_photo",
         "existing_preset",
         "existing_photo"
      ])
   }

   @Test("FAEvent名はFirebaseのカスタムイベント制約に収まる")
   func eventNamesFitFirebaseCustomEventRules() {
      let allowedScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")

      for eventName in FAEventName.allCases.map(\.rawValue) {
         #expect(eventName.count <= 40)
         #expect(eventName.first?.isLetter == true)
         #expect(eventName.unicodeScalars.allSatisfy { allowedScalars.contains($0) })
      }
   }

   @Test("買い切りプレミアム購入イベントは商品IDと価格表示を含む")
   func premiumPurchaseEventIncludesProductIDAndPriceText() {
      let event = FAEvent.purchase(
         productID: LikehateRevenueCatContracts.premiumProductID,
         price: "¥800",
         parameters: [.source: "purchase"]
      )

      #expect(event.name == AnalyticsEventPurchase)
      #expect(event.parameters?[AnalyticsParameterItemID] as? String == "NO_ADS_LIKEHATE")
      #expect(event.parameters?[AnalyticsParameterItemName] as? String == "premium_lifetime")
      #expect(event.parameters?["price_text"] as? String == "¥800")
      #expect(event.parameters?["source"] as? String == "purchase")
   }

   @Test("買い切りプレミアム購入イベントは価格未取得なら価格表示を含めない")
   func premiumPurchaseEventOmitsPriceTextWhenUnavailable() {
      let event = FAEvent.purchase(
         productID: LikehateRevenueCatContracts.premiumProductID,
         price: nil,
         parameters: [.source: "purchase"]
      )

      #expect(event.name == AnalyticsEventPurchase)
      #expect(event.parameters?[AnalyticsParameterItemID] as? String == "NO_ADS_LIKEHATE")
      #expect(event.parameters?["price_text"] == nil)
      #expect(event.parameters?["source"] as? String == "purchase")
   }

   @Test("FAParameterは送信キーを重複なく一覧化する")
   func parameterKeysAreListedAndUnique() {
      let keys = FAParameter.allCases.map(\.key)

      #expect(keys.count == Set(keys).count)
      #expect(keys.allSatisfy { $0.isEmpty == false })
      #expect(keys.contains("source"))
      #expect(keys.contains("entry_text"))
      #expect(keys.contains("person_count"))
      #expect(keys.contains("person_name"))
      #expect(keys.contains("product_id"))
      #expect(keys.contains("profile_image_source"))
      #expect(keys.contains(AnalyticsParameterScreenName))
      #expect(keys.contains(AnalyticsParameterItemID))
   }

   @Test("主要な課金イベント名がFAEventに定義されている")
   func premiumLifecycleEventsAreDefined() {
      let names = Set(FAEventName.allCases.map(\.rawValue))

      #expect(names.contains("premium_product_fetch_started"))
      #expect(names.contains("premium_product_fetch_succeeded"))
      #expect(names.contains("premium_purchase_started"))
      #expect(names.contains("premium_purchase_succeeded"))
      #expect(names.contains("premium_purchase_cancelled"))
      #expect(names.contains("premium_purchase_failed"))
      #expect(names.contains("premium_restore_started"))
      #expect(names.contains("premium_restore_succeeded"))
      #expect(names.contains("premium_restore_empty"))
      #expect(names.contains("premium_entitlement_updated"))
   }
}
