import Foundation

extension Notification.Name {
   /// 旧広告非表示購入が反映されたことを伝える通知。
   static let didRemoveAds = Notification.Name("Likehate.didRemoveAds")
   /// RevenueCatのプレミアム権利状態が更新されたことを伝える通知。
   static let didUpdatePremiumEntitlement = Notification.Name("Likehate.didUpdatePremiumEntitlement")
}

/// プレミアム権利更新通知に載せるuserInfoキー。
enum PremiumEntitlementNotificationUserInfoKey {
   /// プレミアム権利が有効かどうか。
   static let isPremiumActive = "isPremiumActive"
}
