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
   @Test("画面表示イベントはFirebase標準のscreen_viewを使う")
   func screenViewUsesFirebaseScreenEvent() {
      let event = FAEvent.screenView(.premium, parameters: [.source: "settings"])

      #expect(event.name == AnalyticsEventScreenView)
      #expect(event.parameters?[AnalyticsParameterScreenName] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?[AnalyticsParameterScreenClass] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?["source"] as? String == "settings")
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

   @Test("FAParameterは送信キーを重複なく一覧化する")
   func parameterKeysAreListedAndUnique() {
      let keys = FAParameter.allCases.map(\.key)

      #expect(keys.count == Set(keys).count)
      #expect(keys.contains("source"))
      #expect(keys.contains("person_count"))
      #expect(keys.contains("product_id"))
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
