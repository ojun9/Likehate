import Firebase
import FirebaseAnalytics
import GoogleMobileAds
import SwiftyStoreKit
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      print("本番のfirebaseにアクセス")
      FirebaseApp.configure()
      configureAnalyticsCollection()
      MobileAds.shared.start(completionHandler: nil)
      completePendingPurchases()
      return true
   }

   private func completePendingPurchases() {
      SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
         for purchase in purchases {
            switch purchase.transaction.transactionState {
            case .purchased, .restored:
               if purchase.needsFinishTransaction {
                  SwiftyStoreKit.finishTransaction(purchase.transaction)
               }
            case .failed, .purchasing, .deferred:
               break
            @unknown default:
               break
            }
         }
      }
   }

   private func configureAnalyticsCollection() {
      #if DEBUG
      Analytics.setAnalyticsCollectionEnabled(false)
      #endif
   }
}
