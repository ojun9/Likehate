import SwiftUI

/// アプリ全体のNavigationStackを保持するルートView。
struct RootView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var onboardingSource: OnboardingPresentationSource?

   var body: some View {
      NavigationStack {
         HomeView { source in
            onboardingSource = source
         }
      }
      .fullScreenCover(item: $onboardingSource) { source in
         NavigationStack {
            OnboardingView(source: source) {
               if source == .automatic {
                  store.completeOnboarding()
               }
            }
         }
         .interactiveDismissDisabled()
      }
      .onAppear {
         presentOnboardingIfNeeded()
      }
      .onChange(of: store.shouldPresentOnboarding) {
         presentOnboardingIfNeeded()
      }
   }

   private func presentOnboardingIfNeeded() {
      guard store.shouldPresentOnboarding else { return }
      onboardingSource = .automatic
   }
}
