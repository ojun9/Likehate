import Firebase
import FirebaseAnalytics
import GoogleMobileAds
import RevenueCat
import UIKit

/// Firebase、AdMob、RevenueCatなどアプリ起動時に必要なSDKを初期化する。
final class AppDelegate: NSObject, UIApplicationDelegate {
   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      print("本番のfirebaseにアクセス")
      FirebaseApp.configure()
      configureAnalyticsCollection()
      MobileAds.shared.start(completionHandler: nil)
      configureRevenueCat()
      return true
   }

   /// RevenueCat SDKを設定し、権利更新を受け取れるようにする。
   private func configureRevenueCat() {
      #if DEBUG
      Purchases.logLevel = .debug
      #endif

      Purchases.configure(
         with: Configuration.Builder(withAPIKey: LikehateRevenueCatContracts.publicSDKKey)
            .build()
      )
      Purchases.shared.delegate = self
   }

   /// Firebase Analyticsの収集を有効にする。
   private func configureAnalyticsCollection() {
      Analytics.setAnalyticsCollectionEnabled(true)
   }
}

/// RevenueCatから届いた購入権利の更新をアプリ内ストアへ通知する。
extension AppDelegate: @MainActor PurchasesDelegate {
   func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
      guard let isPremiumActive = customerInfo.likehatePremiumEntitlementIsActive else { return }
      FAAnalytics.log(.track(.premiumEntitlementUpdated, parameters: [
         .isPremium: isPremiumActive
      ]))
      NotificationCenter.default.post(
         name: .didUpdatePremiumEntitlement,
         object: nil,
         userInfo: [PremiumEntitlementNotificationUserInfoKey.isPremiumActive: isPremiumActive]
      )
   }
}
