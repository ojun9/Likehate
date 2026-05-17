import FirebaseAnalytics
import SwiftUI

struct RootSwiftUIView: View {
   var body: some View {
      NavigationStack {
         HomeSwiftUIView()
      }
   }
}

struct HomeSwiftUIView: View {
   @EnvironmentObject private var store: LikeHateStore

   var body: some View {
      GeometryReader { proxy in
         ZStack {
            Color(.systemGray6)
               .ignoresSafeArea()

            HomeLottieLayer(size: proxy.size)

            VStack(spacing: proxy.size.width / 20) {
               if !store.didBuyRemoveAd {
                  HStack(spacing: 12) {
                     PurchaseControlButton(
                        title: NSLocalizedString("No Ads", comment: ""),
                        isLoading: store.isPurchasing,
                        action: store.purchaseNoAds
                     )

                     PurchaseControlButton(
                        title: NSLocalizedString("Restore", comment: ""),
                        isLoading: store.isRestoring,
                        action: store.restorePurchases
                     )
                  }
                  .frame(height: max(58, proxy.size.height / 11))
               }

               Spacer(minLength: proxy.size.height * 0.14)

               NavigationLink {
                  ChooseEntrySwiftUIView()
               } label: {
                  HomeImageButton(imageName: "set", title: NSLocalizedString("register", comment: ""))
               }

               NavigationLink {
                  ItemListSwiftUIView(kind: .like)
               } label: {
                  HomeImageButton(imageName: "like", title: NSLocalizedString("Like", comment: ""))
               }

               NavigationLink {
                  ItemListSwiftUIView(kind: .hate)
               } label: {
                  HomeImageButton(imageName: "hate", title: NSLocalizedString("Hate", comment: ""))
               }
            }
            .padding(.horizontal, proxy.size.width / 20)
            .padding(.bottom, 12)
         }
      }
      .navigationTitle(NSLocalizedString("home", comment: ""))
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
            primaryButton: .default(Text(NSLocalizedString("ThankYou", comment: ""))) {
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text(NSLocalizedString("Ohthankyou", comment: ""))) {
               Analytics.logEvent("UserTap_OhThanks...For100", parameters: nil)
            }
         )
      }
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
               SettingsSwiftUIView()
            } label: {
               Image(systemName: "gearshape")
            }
            .accessibilityLabel(NSLocalizedString("Settings", comment: ""))
         }
      }
      .onAppear {
         Analytics.logEvent("showSwiftUIHome", parameters: nil)
      }
   }
}

struct PurchaseControlButton: View {
   let title: String
   let isLoading: Bool
   let action: () -> Void

   var body: some View {
      Button(action: action) {
         ZStack {
            if isLoading {
               ProgressView()
                  .tint(.white)
            } else {
               Text(title)
                  .font(.headline.bold())
                  .minimumScaleFactor(0.55)
                  .lineLimit(1)
            }
         }
         .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .background(Color(red: 0.353, green: 0.737, blue: 0.816), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .shadow(color: Color(red: 0.255, green: 0.592, blue: 0.671).opacity(0.45), radius: 0, x: 0, y: 3)
      .disabled(isLoading)
   }
}

struct HomeImageButton: View {
   let imageName: String
   let title: String

   var body: some View {
      Image(imageName)
         .resizable()
         .scaledToFit()
         .accessibilityLabel(title)
         .frame(maxWidth: .infinity)
         .frame(height: 150)
         .padding(.horizontal, 8)
         .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
         .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
               .stroke(Color.primary.opacity(0.75), lineWidth: 1.5)
         )
         .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 2)
   }
}

struct HomeLottieLayer: View {
   let size: CGSize

   var body: some View {
      ZStack {
         let earthSize = size.height / 10
         let sparkleWidth = size.width * 0.45
         let sparkleHeight = size.height / 5
         let lightningSize = size.height / 5

         LottieLoopView(name: "earth")
            .frame(width: earthSize, height: earthSize)
            .position(x: size.width - (earthSize / 2 + size.width / 20), y: earthSize / 2 + size.width / 10)

         LottieLoopView(name: "Kaminari")
            .opacity(0.7)
            .frame(width: lightningSize, height: lightningSize)
            .position(x: size.width / 20 + lightningSize / 2, y: size.height - (size.height / 10 + 15))

         LottieLoopView(name: "KiraKira")
            .opacity(0.8)
            .frame(width: sparkleWidth, height: sparkleHeight)
            .scaleEffect(1.4)
            .position(x: size.width / 20 + sparkleWidth / 2, y: size.height * 0.475)

         LottieLoopView(name: "KiraKira")
            .opacity(0.8)
            .frame(width: sparkleWidth, height: sparkleHeight)
            .scaleEffect(1.4)
            .position(x: size.width * 0.45 + sparkleWidth / 2, y: size.height * 0.575)
      }
      .allowsHitTesting(false)
   }
}
