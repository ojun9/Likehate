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
   @State private var isShowingSettings = false

   var body: some View {
      GeometryReader { proxy in
         ZStack {
            Color(.systemGray6)
               .ignoresSafeArea()

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

            VStack(spacing: proxy.size.width / 20) {
               if !store.didBuyRemoveAd {
                  PurchaseActionsView(
                     isPurchasing: store.isPurchasing,
                     isRestoring: store.isRestoring,
                     purchase: store.purchaseNoAds,
                     restore: store.restorePurchases
                  )
               }

               Spacer(minLength: proxy.size.height * 0.14)

               NavigationLink {
                  ChooseEntrySwiftUIView()
               } label: {
                  HomeImageButton(imageName: "set", height: proxy.size.height / 5, accessibilityLabel: "register")
               }

               NavigationLink {
                  ItemListSwiftUIView(kind: .like)
               } label: {
                  HomeImageButton(imageName: "like", height: proxy.size.height / 5, accessibilityLabel: "Like")
               }

               NavigationLink {
                  ItemListSwiftUIView(kind: .hate)
               } label: {
                  HomeImageButton(imageName: "hate", height: proxy.size.height / 5, accessibilityLabel: "Hate")
               }
            }
            .padding(.horizontal, proxy.size.width / 20)
            .padding(.bottom, 12)
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
            SettingsSwiftUIView()
         }
      }
      .onAppear {
         Analytics.logEvent("showSwiftUIHome", parameters: nil)
      }
   }
}

struct PurchaseActionsView: View {
   let isPurchasing: Bool
   let isRestoring: Bool
   let purchase: () -> Void
   let restore: () -> Void

   var body: some View {
      HStack(spacing: 12) {
         Button(action: purchase) {
            ZStack {
               if isPurchasing {
                  ProgressView()
                     .tint(.white)
               } else {
                  Text("No Ads")
                     .font(.headline)
                     .fontWeight(.semibold)
                     .lineLimit(1)
               }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color(red: 0.957, green: 0.275, blue: 0.365), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
         }
         .buttonStyle(.plain)
         .disabled(isPurchasing)

         Button(action: restore) {
            ZStack {
               if isRestoring {
                  ProgressView()
               } else {
                  Text("Restore")
                     .font(.subheadline)
                     .fontWeight(.semibold)
                     .lineLimit(1)
               }
            }
            .foregroundStyle(.secondary)
            .frame(width: 92, minHeight: 48)
         }
         .buttonStyle(.plain)
         .disabled(isRestoring)
      }
      .padding(8)
      .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
      )
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
            .scaledToFit()
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
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
            .position(x: size.width / 20 + sparkleWidth / 2, y: size.height * 0.475)

         LottieLoopView(name: "KiraKira")
            .opacity(0.8)
            .frame(width: sparkleWidth, height: sparkleHeight)
            .position(x: size.width * 0.45 + sparkleWidth / 2, y: size.height * 0.575)
      }
      .allowsHitTesting(false)
   }
}
