import SwiftUI

/// 入力画面上部にLottieを安全に重ねる背景レイヤー。
struct WriteLottieLayer: View {
   let lottieName: String
   let kind: EntryKind
   let keepsFullHeight: Bool
   @State private var largestSize: CGSize = .zero

   var body: some View {
      GeometryReader { proxy in
         let stableHeight = keepsFullHeight ? max(largestSize.height, proxy.size.height) : proxy.size.height

         ZStack(alignment: .top) {
            LottieLoopView(name: lottieName)
               .frame(width: proxy.size.width * 0.96, height: max(stableHeight - 15, 120))
               .frame(maxWidth: .infinity, alignment: .top)
               .padding(.horizontal, proxy.size.width * 0.02)
         }
         .frame(width: proxy.size.width, height: stableHeight, alignment: .top)
         .onAppear {
            largestSize = proxy.size
         }
         .onChange(of: proxy.size) { _, newSize in
            if !keepsFullHeight || newSize.height > largestSize.height {
               largestSize = newSize
            }
         }
      }
      .opacity(kind == .like ? 0.72 : 0.32)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .ignoresSafeArea(.container, edges: .top)
      .ignoresSafeArea(.keyboard, edges: .bottom)
   }
}
