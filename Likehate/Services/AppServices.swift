import StoreKit
import SwiftUI
import UIKit

/// アプリ全体で使う触覚フィードバックの薄いラッパー。
enum HapticsClient {
   private static let isEnabledKey = "HapticsEnabled"

   private static var isEnabled: Bool {
      let defaults = UserDefaults.standard
      guard defaults.object(forKey: isEnabledKey) != nil else { return true }
      return defaults.bool(forKey: isEnabledKey)
   }

   /// 軽い選択や補助操作で使うフィードバック。
   @MainActor
   static func light() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
   }

   /// 中程度の操作で使うフィードバック。
   @MainActor
   static func medium() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
   }

   /// 重要な確認操作で使う強めのフィードバック。
   @MainActor
   static func heavy() {
      guard isEnabled else { return }
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
   }

   /// 保存や購入成功などで使う成功フィードバック。
   @MainActor
   static func success() {
      guard isEnabled else { return }
      UINotificationFeedbackGenerator().notificationOccurred(.success)
   }

   /// 入力エラーなどで使う失敗フィードバック。
   @MainActor
   static func error() {
      guard isEnabled else { return }
      UINotificationFeedbackGenerator().notificationOccurred(.error)
   }
}

/// App Storeレビュー依頼を出すためのラッパー。
enum AppReviewClient {
   /// 現在のSceneが取れる場合は標準レビュー依頼、取れない場合はストアURLへフォールバックする。
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
   /// 現在キーウィンドウを持つScene。
   var likehateWindowScene: UIWindowScene? {
      connectedScenes
         .compactMap { $0 as? UIWindowScene }
         .first { scene in
            scene.windows.contains(where: \.isKeyWindow)
         }
   }

   /// AdMobなどUIKitブリッジが使う現在のrootViewController。
   var likehateRootViewController: UIViewController? {
      likehateWindowScene?
         .windows
         .first(where: \.isKeyWindow)?
         .rootViewController
   }
}
