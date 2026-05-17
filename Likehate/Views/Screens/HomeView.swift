import FirebaseAnalytics
import SwiftUI

struct RootView: View {
   var body: some View {
      NavigationStack {
         HomeView()
      }
   }
}

struct HomeView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var isShowingSettings = false
   @State private var isShowingChooseEntry = false
   @State private var showsHomeLottie = true

   var body: some View {
      GeometryReader { proxy in
         let horizontalPadding = proxy.size.width / 20
         let isLandscape = proxy.size.width > proxy.size.height
         let spacing = isLandscape ? 10.0 : max(proxy.size.width / 24, 14)
         let contentMinHeight = max(proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - 24, 0)

         ZStack {
            Color(.systemGray6)
               .ignoresSafeArea()

            ScrollView(.vertical) {
               VStack(spacing: spacing) {
                  Spacer(minLength: isLandscape ? 8 : 18)

                  VStack(spacing: spacing) {
                     registerButton()
                     likeButton()
                     hateButton()
                  }

                  Spacer(minLength: isLandscape ? 14 : 56)
               }
               .frame(maxWidth: .infinity)
               .frame(minHeight: contentMinHeight)
               .padding(.horizontal, horizontalPadding)
               .padding(.top, max(proxy.safeAreaInsets.top + 8, 12))
               .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 16))
            }
            .scrollIndicators(.hidden)
         }
      }
      .navigationTitle("AppTitle")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(isPresented: $isShowingChooseEntry) {
         ChooseEntryView()
      }
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            Button {
               isShowingSettings = true
            } label: {
               Image(systemName: "gearshape")
            }
            .accessibilityLabel(Text("SettingsTitle"))
         }
      }
      .alert(item: $store.purchaseMessage) { message in
         Alert(
            title: Text(message.title),
            message: Text(message.message),
            dismissButton: .default(Text("OK"))
         )
      }
      .alert(item: $store.reviewPrompt) { prompt in
         Alert(
            title: Text(prompt.title),
            message: Text(prompt.message),
            primaryButton: .default(Text("ThankYou")) {
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               Analytics.logEvent("UserTap_OhThanks...For100", parameters: nil)
            }
         )
      }
      .sheet(isPresented: $isShowingSettings) {
         NavigationStack {
            SettingsView()
         }
         .presentationDetents([.medium, .large])
         .presentationDragIndicator(.visible)
         .presentationCompactAdaptation(.sheet)
      }
      .onAppear {
         showsHomeLottie = true
         Analytics.logEvent("showSwiftUIHome", parameters: nil)
      }
   }

   private func registerButton() -> some View {
      Button {
         showsHomeLottie = false
         isShowingChooseEntry = true
      } label: {
         HomeImageButton(imageName: "set", accessibilityLabel: "register")
      }
      .buttonStyle(.plain)
   }

   private func likeButton() -> some View {
      NavigationLink {
         ItemListView(kind: .like)
      } label: {
         HomeImageButton(imageName: "like", accessibilityLabel: "Like", overlayLottie: showsHomeLottie ? .kiraKira : nil)
      }
      .simultaneousGesture(TapGesture().onEnded {
         showsHomeLottie = false
      })
   }

   private func hateButton() -> some View {
      NavigationLink {
         ItemListView(kind: .hate)
      } label: {
         HomeImageButton(imageName: "hate", accessibilityLabel: "Hate", overlayLottie: showsHomeLottie ? .kaminari : nil)
      }
      .simultaneousGesture(TapGesture().onEnded {
         showsHomeLottie = false
      })
   }
}

enum HomeButtonLottie {
   case kiraKira
   case kaminari

   var name: String {
      switch self {
      case .kiraKira: return "KiraKira"
      case .kaminari: return "Kaminari"
      }
   }

   var opacity: Double {
      switch self {
      case .kiraKira: return 0.78
      case .kaminari: return 0.7
      }
   }

   func frame(in size: CGSize) -> CGSize {
      switch self {
      case .kiraKira:
         return CGSize(width: size.width * 0.9, height: size.height * 0.72)
      case .kaminari:
         return CGSize(width: size.height * 0.95, height: size.height * 0.95)
      }
   }

   func position(in size: CGSize) -> CGPoint {
      switch self {
      case .kiraKira:
         return CGPoint(x: size.width * 0.5, y: size.height * 0.5)
      case .kaminari:
         return CGPoint(x: size.width * 0.16, y: size.height * 0.62)
      }
   }
}

struct HomeImageButton: View {
   private static let imageAspectRatio = 2058.0 / 690.0

   let imageName: String
   let accessibilityLabel: LocalizedStringKey
   var overlayLottie: HomeButtonLottie?

   var body: some View {
      ZStack {
         RoundedRectangle(cornerRadius: 25, style: .continuous)
            .fill(Color(.systemBackground))

         Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

         if let overlayLottie {
            GeometryReader { proxy in
               let lottieSize = overlayLottie.frame(in: proxy.size)
               let lottiePosition = overlayLottie.position(in: proxy.size)

               LottieLoopView(name: overlayLottie.name)
                  .opacity(overlayLottie.opacity)
                  .frame(width: lottieSize.width, height: lottieSize.height)
                  .clipped()
                  .position(lottiePosition)
                  .allowsHitTesting(false)
            }
            .clipped()
         }
      }
      .frame(maxWidth: .infinity)
      .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 25, style: .continuous)
            .stroke(Color.primary.opacity(0.48), lineWidth: 1)
      )
      .shadow(color: .black.opacity(0.11), radius: 8, x: 0, y: 2)
      .contentShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
      .accessibilityLabel(Text(accessibilityLabel))
   }
}
