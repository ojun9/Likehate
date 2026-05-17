import Firebase
import FirebaseAnalytics
import FirebaseMessaging
import GoogleMobileAds
import SwiftyStoreKit
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      print("本番のfirebaseにアクセス")
      FirebaseApp.configure()
      configureAnalyticsCollection()
      MobileAds.shared.start(completionHandler: nil)
      completePendingPurchases()
      configurePushNotifications(application)
      UNUserNotificationCenter.current().setBadgeCount(0)
      return true
   }

   func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      logRemoteNotification(userInfo)
   }

   func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      logRemoteNotification(userInfo)
      completionHandler(.newData)
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

   private func configurePushNotifications(_ application: UIApplication) {
      Messaging.messaging().delegate = self
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
      application.registerForRemoteNotifications()
   }

   private func logRemoteNotification(_ userInfo: [AnyHashable: Any]) {
      if let messageID = userInfo["gcm.message_id"] {
         print("メッセージID: \(messageID)")
      }

      print(userInfo)
   }
}

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      logRemoteNotification(notification.request.content.userInfo)
      completionHandler([])
   }

   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
      logRemoteNotification(response.notification.request.content.userInfo)
      completionHandler()
   }
}

extension AppDelegate: @preconcurrency MessagingDelegate {
   func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      guard let fcmToken else { return }
      print("Firebase registration token: \(fcmToken)")

      let dataDict = ["token": fcmToken]
      NotificationCenter.default.post(name: .didReceiveFCMToken, object: nil, userInfo: dataDict)
   }
}
