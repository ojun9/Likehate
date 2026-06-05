import Foundation

extension Notification.Name {
   static let didRemoveAds = Notification.Name("Likehate.didRemoveAds")
   static let didUpdatePremiumEntitlement = Notification.Name("Likehate.didUpdatePremiumEntitlement")
}

enum PremiumEntitlementNotificationUserInfoKey {
   static let isPremiumActive = "isPremiumActive"
}
