import StoreKit
import SwiftUI
import UIKit

enum HapticsClient {
   static func light() {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
   }

   static func medium() {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
   }

   static func heavy() {
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
   }

   static func success() {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
   }

   static func error() {
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
