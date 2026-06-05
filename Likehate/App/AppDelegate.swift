import Firebase
import FirebaseAnalytics
import GoogleMobileAds
import RevenueCat
import UIKit

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

   private func configureAnalyticsCollection() {
      Analytics.setAnalyticsCollectionEnabled(true)
   }
}

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
