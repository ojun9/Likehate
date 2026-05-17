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

   var body: some View {
      GeometryReader { proxy in
         let horizontalPadding = proxy.size.width / 20
         let isLandscape = proxy.size.width > proxy.size.height
         let mainButtonHeight = isLandscape ? min(max(proxy.size.height * 0.42, 110), 170) : proxy.size.height / 5
         let spacing = isLandscape ? 12.0 : proxy.size.width / 20

         ZStack {
            Color(.systemGray6)
               .ignoresSafeArea()

            ScrollView(.vertical) {
               VStack(spacing: spacing) {
                  purchaseActions(width: proxy.size.width)

                  Spacer(minLength: isLandscape ? 24 : mainButtonHeight * 0.7)

                  VStack(spacing: spacing) {
                     registerButton(height: mainButtonHeight)
                     likeButton(height: mainButtonHeight)
                     hateButton(height: mainButtonHeight)
                  }
               }
               .frame(maxWidth: .infinity)
               .padding(.horizontal, horizontalPadding)
               .padding(.top, max(proxy.safeAreaInsets.top + 8, 12))
               .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 16))
            }
            .scrollIndicators(.hidden)

            HomeLottieLayer(size: proxy.size)

            VStack {
               HStack {
                  Spacer()
                  Button {
                     isShowingSettings = true
                  } label: {
                     Image(systemName: "gearshape")
                        .font(.title3)
                  }
                  .buttonStyle(.bordered)
                  .buttonBorderShape(.circle)
                  .accessibilityLabel(Text("Settings"))
               }
               .padding(.top, max(proxy.safeAreaInsets.top, 12))
               .padding(.trailing, proxy.size.width / 20)

               Spacer()
            }
            .zIndex(10)
         }
      }
      .toolbar(.hidden, for: .navigationBar)
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
         Analytics.logEvent("showSwiftUIHome", parameters: nil)
      }
   }

   @ViewBuilder
   private func purchaseActions(width: CGFloat) -> some View {
      if !store.didBuyRemoveAd {
         PurchaseActionsView(
            width: width / 3,
            isPurchasing: store.isPurchasing,
            isRestoring: store.isRestoring,
            purchase: store.purchaseNoAds,
            restore: store.restorePurchases
         )
      }
   }

   private func registerButton(height: CGFloat) -> some View {
      NavigationLink {
         ChooseEntryView()
      } label: {
         HomeImageButton(imageName: "set", height: height, accessibilityLabel: "register")
      }
   }

   private func likeButton(height: CGFloat) -> some View {
      NavigationLink {
         ItemListView(kind: .like)
      } label: {
         HomeImageButton(imageName: "like", height: height, accessibilityLabel: "Like")
      }
   }

   private func hateButton(height: CGFloat) -> some View {
      NavigationLink {
         ItemListView(kind: .hate)
      } label: {
         HomeImageButton(imageName: "hate", height: height, accessibilityLabel: "Hate")
      }
   }
}

struct PurchaseActionsView: View {
   let width: CGFloat
   let isPurchasing: Bool
   let isRestoring: Bool
   let purchase: () -> Void
   let restore: () -> Void

   var body: some View {
      VStack(spacing: 8) {
         purchaseButton
         restoreButton
      }
      .font(.callout.weight(.semibold))
      .controlSize(.large)
      .buttonBorderShape(.roundedRectangle(radius: 8))
      .frame(width: width, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .leading)
   }

   private var purchaseButton: some View {
      Button(action: purchase) {
         Group {
            if isPurchasing {
               ProgressView()
                  .tint(.white)
            } else {
               Text("No Ads")
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)
            }
         }
         .frame(minHeight: 34)
         .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color(red: 0.957, green: 0.275, blue: 0.365))
      .disabled(isPurchasing)
      .frame(maxWidth: .infinity)
   }

   private var restoreButton: some View {
      Button(action: restore) {
         Group {
            if isRestoring {
               ProgressView()
            } else {
               Text("Restore")
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)
            }
         }
         .frame(minHeight: 34)
         .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .disabled(isRestoring)
      .frame(maxWidth: .infinity)
   }
}

struct HomeImageButton: View {
   let imageName: String
   let height: CGFloat
   let accessibilityLabel: LocalizedStringKey

   var body: some View {
      ZStack {
         RoundedRectangle(cornerRadius: 25, style: .continuous)
            .fill(Color(.systemBackground))

         Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
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
         let earthSize = min(size.width * 0.12, size.height * 0.055)
         let sparkleWidth = size.width * 0.34
         let sparkleHeight = size.height * 0.14
         let lightningSize = size.height * 0.13

         LottieLoopView(name: "earth")
            .frame(width: earthSize, height: earthSize)
            .position(x: size.width - horizontalInset - earthSize, y: size.height * 0.105)

         LottieLoopView(name: "Kaminari")
            .opacity(0.7)
            .frame(width: lightningSize, height: lightningSize)
            .position(x: size.width / 20 + lightningSize / 2, y: size.height - (size.height / 10 + 15))

         LottieLoopView(name: "KiraKira")
            .opacity(0.8)
            .frame(width: sparkleWidth, height: sparkleHeight)
            .position(x: size.width / 20 + sparkleWidth / 2, y: size.height * 0.49)

         LottieLoopView(name: "KiraKira")
            .opacity(0.8)
            .frame(width: sparkleWidth, height: sparkleHeight)
            .position(x: size.width * 0.53 + sparkleWidth / 2, y: size.height * 0.59)
      }
      .allowsHitTesting(false)
   }
}
