import UIKit
import GoogleMobileAds
import Lottie

typealias AnimationView = LottieAnimationView
typealias GADBannerView = BannerView
typealias GADRequest = Request
typealias GADBannerViewDelegate = BannerViewDelegate
typealias GADRequestError = Error

protocol GADInterstitialDelegate: AnyObject {}

final class GADInterstitial {
   weak var delegate: GADInterstitialDelegate?
   let adUnitID: String?
   var isReady: Bool { false }

   init(adUnitID: String) {
      self.adUnitID = adUnitID
   }

   func load(_ request: GADRequest) {}
   func present(fromRootViewController viewController: UIViewController) {}
}

enum TapticEngine {
   enum impact {
      static func feedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
         UIImpactFeedbackGenerator(style: style).impactOccurred()
      }
   }

   enum notification {
      static func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
         UINotificationFeedbackGenerator().notificationOccurred(type)
      }
   }
}

class FUIButton: UIButton {
   var buttonColor: UIColor = .systemBlue {
      didSet { backgroundColor = buttonColor }
   }
   var shadowColor: UIColor = .clear {
      didSet { layer.shadowColor = shadowColor.cgColor }
   }
   var shadowHeight: CGFloat = 0 {
      didSet {
         layer.shadowOffset = CGSize(width: 0, height: shadowHeight)
         layer.shadowOpacity = shadowHeight > 0 ? 0.25 : 0
      }
   }
   var cornerRadius: CGFloat = 0 {
      didSet { layer.cornerRadius = cornerRadius }
   }
}

final class FUITextField: UITextField {
   var edgeInsets: UIEdgeInsets = .zero
   var textFieldColor: UIColor = .white {
      didSet { backgroundColor = textFieldColor }
   }
   var borderColor: UIColor = .clear {
      didSet { layer.borderColor = borderColor.cgColor }
   }
   var borderWidth: CGFloat = 0 {
      didSet { layer.borderWidth = borderWidth }
   }
   var cornerRadius: CGFloat = 0 {
      didSet { layer.cornerRadius = cornerRadius }
   }

   override func textRect(forBounds bounds: CGRect) -> CGRect {
      bounds.inset(by: edgeInsets)
   }

   override func editingRect(forBounds bounds: CGRect) -> CGRect {
      bounds.inset(by: edgeInsets)
   }
}

final class HeartLoadingView: UIView {
   var progress: CGFloat = 0
   var heartAmplitude: CGFloat = 0
   var isAnimated: Bool = false
}

final class SCLAlertView {
   struct SCLAppearance {
      let showCloseButton: Bool
   }

   private var buttons: [(String, () -> Void)] = []

   init(appearance: SCLAppearance = SCLAppearance(showCloseButton: true)) {}

   func addButton(_ title: String, action: @escaping () -> Void) {
      buttons.append((title, action))
   }

   func showSuccess(_ title: String, subTitle: String) {
      show(title: title, message: subTitle)
   }

   func showWarning(_ title: String, subTitle: String) {
      show(title: title, message: subTitle)
   }

   private func show(title: String, message: String) {
      guard let presenter = UIApplication.shared.connectedScenes
         .compactMap({ $0 as? UIWindowScene })
         .flatMap({ $0.windows })
         .first(where: { $0.isKeyWindow })?
         .rootViewController?
         .topPresentedViewController
      else {
         buttons.first?.1()
         return
      }

      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      if buttons.isEmpty {
         alert.addAction(UIAlertAction(title: "OK", style: .default))
      } else {
         for button in buttons {
            alert.addAction(UIAlertAction(title: button.0, style: .default) { _ in button.1() })
         }
      }
      presenter.present(alert, animated: true)
   }
}

private extension UIViewController {
   var topPresentedViewController: UIViewController {
      presentedViewController?.topPresentedViewController ?? self
   }
}

extension UIColor {
   static func flatWatermelon() -> UIColor { UIColor(red: 0.957, green: 0.275, blue: 0.365, alpha: 1) }
   static func flatWatermelonColorDark() -> UIColor { UIColor(red: 0.782, green: 0.167, blue: 0.251, alpha: 1) }
   static func flatPowderBlue() -> UIColor { UIColor(red: 0.353, green: 0.737, blue: 0.816, alpha: 1) }
   static func flatPowderBlueColorDark() -> UIColor { UIColor(red: 0.255, green: 0.592, blue: 0.671, alpha: 1) }
   static func flatMint() -> UIColor { UIColor(red: 0.243, green: 0.780, blue: 0.620, alpha: 1) }
   static func flatMagenta() -> UIColor { UIColor(red: 0.608, green: 0.349, blue: 0.714, alpha: 1) }
   static func flatWhite() -> UIColor { UIColor(white: 0.96, alpha: 1) }
   static func flatBlack() -> UIColor? { UIColor(white: 0.12, alpha: 1) }
   static func turquoise() -> UIColor { UIColor(red: 0.102, green: 0.737, blue: 0.612, alpha: 1) }
   static func clouds() -> UIColor { UIColor(white: 0.96, alpha: 1) }
}

extension UIFont {
   static func boldFlatFont(ofSize size: CGFloat) -> UIFont {
      UIFont.boldSystemFont(ofSize: size)
   }
}
