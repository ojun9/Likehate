import StoreKit
import SwiftUI
import UIKit

enum HapticsClient {
   private static let isEnabledKey = "HapticsEnabled"

   private static var isEnabled: Bool {
      let defaults = UserDefaults.standard
      guard defaults.object(forKey: isEnabledKey) != nil else { return true }
      return defaults.bool(forKey: isEnabledKey)
   }

   static func light() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
   }

   static func medium() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
   }

   static func heavy() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
   }

   static func success() {
      guard isEnabled else { return }
      UINotificationFeedbackGenerator().notificationOccurred(.success)
   }

   static func error() {
      guard isEnabled else { return }
      UINotificationFeedbackGenerator().notificationOccurred(.error)
   }
}

enum AppReviewClient {
   @MainActor
   static func requestReview() {
      guard let scene = UIApplication.shared.likehateWindowScene else {
         if let url = URL(string: "itms-apps://itunes.apple.com/app/id1479237734?action=write-review") {
            UIApplication.shared.open(url)
         }
         return
      }

      AppStore.requestReview(in: scene)
   }
}

extension UIApplication {
   var likehateWindowScene: UIWindowScene? {
      connectedScenes
         .compactMap { $0 as? UIWindowScene }
         .first { scene in
            scene.windows.contains(where: \.isKeyWindow)
         }
   }

   var likehateRootViewController: UIViewController? {
      likehateWindowScene?
         .windows
         .first(where: \.isKeyWindow)?
         .rootViewController
   }
}
