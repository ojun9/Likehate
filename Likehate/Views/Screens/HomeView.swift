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
         let spacing = isLandscape ? 12.0 : proxy.size.width / 20

         ZStack {
            Color(.systemGray6)
               .ignoresSafeArea()

            ScrollView(.vertical) {
               VStack(spacing: spacing) {
                  Spacer(minLength: isLandscape ? 12 : 48)

                  VStack(spacing: spacing) {
                     registerButton()
                     likeButton()
                     hateButton()
                  }
               }
               .frame(maxWidth: .infinity)
               .padding(.horizontal, horizontalPadding)
               .padding(.top, max(proxy.safeAreaInsets.top + 8, 12))
               .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 16))
            }
            .scrollIndicators(.hidden)

            if showsHomeLottie {
               HomeLottieLayer(size: proxy.size)
            }
         }
      }
      .navigationTitle("Likehate")
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
            .accessibilityLabel(Text("Settings"))
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
         HomeImageButton(imageName: "hate", accessibilityLabel: "Hate", overlayLottie: showsHomeLottie ? .fuwa : nil)
      }
      .simultaneousGesture(TapGesture().onEnded {
         showsHomeLottie = false
      })
   }
}

enum HomeButtonLottie {
   case kiraKira
   case fuwa

   var name: String {
      switch self {
      case .kiraKira: return "KiraKira"
      case .fuwa: return "Fuwa"
      }
   }

   var opacity: Double {
      switch self {
      case .kiraKira: return 0.78
      case .fuwa: return 0.9
      }
   }

   func frame(in size: CGSize) -> CGSize {
      switch self {
      case .kiraKira:
         return CGSize(width: size.width * 0.26, height: size.height * 0.62)
      case .fuwa:
         return CGSize(width: size.width * 0.28, height: size.height * 0.72)
      }
   }

   func position(in size: CGSize) -> CGPoint {
      switch self {
      case .kiraKira:
         return CGPoint(x: size.width * 0.55, y: size.height * 0.52)
      case .fuwa:
         return CGPoint(x: size.width * 0.76, y: size.height * 0.5)
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
                  .position(lottiePosition)
                  .allowsHitTesting(false)
            }
         }
      }
      .frame(maxWidth: .infinity)
      .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 25, style: .continuous)
            .stroke(Color.primary.opacity(0.75), lineWidth: 1.5)
      )
      .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 2)
      .contentShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
      .accessibilityLabel(Text(accessibilityLabel))
   }
}

struct HomeLottieLayer: View {
   let size: CGSize

   var body: some View {
      ZStack {
         let horizontalInset = size.width / 20
         let earthSize = min(size.width * 0.06, size.height * 0.0275)
         let lightningSize = size.height * 0.13

         LottieLoopView(name: "earth")
            .frame(width: earthSize, height: earthSize)
            .position(x: size.width - horizontalInset - (earthSize * 1.2), y: size.height * 0.12)

         LottieLoopView(name: "Kaminari")
            .opacity(0.7)
            .frame(width: lightningSize, height: lightningSize)
            .position(x: size.width / 20 + lightningSize / 2, y: size.height - (size.height / 10 + 15))
      }
      .allowsHitTesting(false)
   }
}
