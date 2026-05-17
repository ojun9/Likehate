import Lottie
import SwiftUI

struct LottieLoopView: UIViewRepresentable {
   let name: String

   func makeUIView(context: Context) -> LottieAnimationView {
      let view = LottieAnimationView(name: name)
      view.backgroundBehavior = .pauseAndRestore
      view.contentMode = .scaleAspectFit
      view.loopMode = .loop
      view.play()
      return view
   }

   func updateUIView(_ uiView: LottieAnimationView, context: Context) {
      if !uiView.isAnimationPlaying {
         uiView.play()
      }
   }
}
