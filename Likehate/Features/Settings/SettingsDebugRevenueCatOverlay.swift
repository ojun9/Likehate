import SwiftUI
#if DEBUG
import RevenueCat
#endif

extension View {
   @ViewBuilder
   func debugRevenueCatOverlayIfDebug(isPresented: Binding<Bool>) -> some View {
      #if DEBUG
      debugRevenueCatOverlay(isPresented: isPresented)
      #else
      self
      #endif
   }
}
