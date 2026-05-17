import Lottie
import SwiftUI

struct LottieLoopView: UIViewRepresentable {
   let name: String

   func makeUIView(context: Context) -> ClippedLottieView {
      ClippedLottieView(name: name)
   }

   func updateUIView(_ uiView: ClippedLottieView, context: Context) {
      uiView.configure(name: name)
   }
}

final class ClippedLottieView: UIView {
   private let animationView = LottieAnimationView()
   private var currentName: String?

   init(name: String) {
      super.init(frame: .zero)
      clipsToBounds = true
      layer.masksToBounds = true

      animationView.translatesAutoresizingMaskIntoConstraints = false
      animationView.backgroundBehavior = .pauseAndRestore
      animationView.contentMode = .scaleAspectFit
      animationView.clipsToBounds = true
      animationView.layer.masksToBounds = true
      animationView.loopMode = .loop

      addSubview(animationView)
      NSLayoutConstraint.activate([
         animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
         animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
         animationView.topAnchor.constraint(equalTo: topAnchor),
         animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
      ])

      configure(name: name)
   }

   @available(*, unavailable)
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func configure(name: String) {
      if currentName != name {
         currentName = name
         animationView.animation = LottieAnimation.named(name)
      }

      if !animationView.isAnimationPlaying {
         animationView.play()
      }
   }
}
