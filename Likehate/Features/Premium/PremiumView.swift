import SwiftUI

/// 買い切りプレミアムの価値説明、購入、復元を行う画面。
struct PremiumView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      ScrollView {
         VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            PremiumHeroPanel()
               .padding(.top, 18)

            PremiumPlanComparison(price: store.premiumProductPrice)

            VStack(alignment: .leading, spacing: 16) {
               PremiumBenefitRow(iconName: "person.3.fill", title: "PremiumBenefitPeople")
               PremiumBenefitRow(iconName: "rectangle.badge.xmark", title: "PremiumBenefitNoAds")
               PremiumBenefitRow(iconName: "checkmark.seal.fill", title: "PremiumBenefitLifetime")
            }
            .padding(layout.cardPadding)
            .background {
               PremiumGlassBackground(
                  cornerRadius: 22,
                  tint: LikehateTheme.likeAccent,
                  opacity: 0.11,
                  borderOpacity: 0.30
               )
            }
         }
         .padding(.horizontal, layout.screenPadding)
         .padding(.bottom, layout.sectionSpacing + 118)
      }
      .background {
         ZStack {
            LikehateTheme.background.ignoresSafeArea()
            LikehateFloatingBackgroundView(blurPlacement: .full, isAnimationEnabled: store.animationEnabled)
         }
      }
      .navigationTitle("PremiumTitle")
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaInset(edge: .bottom) {
         purchaseFooter(typography: typography, layout: layout)
      }
      .alert(item: $store.purchaseMessage) { message in
         Alert(
            title: Text(message.title),
            message: Text(message.message),
            dismissButton: .default(Text("OK"))
         )
      }
      .onAppear {
         store.loadPremiumProductInfo()
         FAAnalytics.log(.screenView(.premium, parameters: premiumAnalyticsParameters))
      }
   }

   private func purchaseFooter(typography: AppTypography, layout: AppLayoutMetrics) -> some View {
      VStack(spacing: 10) {
         Button {
            guard !store.hasPremiumAccess else { return }
            #if DEBUG
            Logger.purchases.debug("purchase button tapped price=\(String(describing: store.premiumProductPrice), privacy: .public)")
            #endif
            FAAnalytics.log(.track(.premiumPurchaseButtonTapped, parameters: premiumAnalyticsParameters))
            store.purchasePremium()
         } label: {
            VStack(spacing: 4) {
               HStack(spacing: 8) {
                  if store.isPurchasing {
                     ProgressView()
                        .tint(.white)
                  } else if store.hasPremiumAccess {
                     Image(systemName: "checkmark.seal.fill")
                        .font(typography.button)
                  }

                  Text(verbatim: purchaseButtonTitle)
                     .font(typography.button)
                     .fontWeight(.bold)
               }

               if let purchaseButtonSubtitle {
                  Text(verbatim: purchaseButtonSubtitle)
                     .font(typography.subtext)
                     .fontWeight(.semibold)
                     .foregroundStyle(purchaseButtonForeground.opacity(0.92))
               }
            }
            .foregroundStyle(purchaseButtonForeground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
            .background(purchaseButtonBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
               RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .strokeBorder(purchaseButtonBorder, lineWidth: 1)
            }
         }
         .buttonStyle(.plain)
         .disabled(store.isPurchasing)
         .accessibilityLabel(Text(verbatim: purchaseButtonAccessibilityLabel))

         Button {
            FAAnalytics.log(.track(.premiumRestoreTapped, parameters: premiumAnalyticsParameters))
            store.restorePurchases()
         } label: {
            if store.isRestoring {
               HStack(spacing: 8) {
                  ProgressView()
                  Text("PremiumRestoreButton")
               }
               .font(typography.subtext)
               .frame(maxWidth: .infinity)
               .frame(minHeight: 42)
            } else {
               Text("PremiumRestoreButton")
                  .font(typography.subtext)
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .frame(minHeight: 42)
            }
         }
         .buttonStyle(.bordered)
         .tint(LikehateTheme.likeAccent)
         .disabled(store.isRestoring)
      }
      .padding(.horizontal, layout.screenPadding)
      .padding(.top, 12)
      .padding(.bottom, 8)
      .background(.thinMaterial)
      .overlay(alignment: .top) {
         Rectangle()
            .fill(LikehateTheme.border)
            .frame(height: 1)
      }
   }

   private var purchaseButtonTitle: String {
      if store.hasPremiumAccess {
         return String(localized: "PremiumPurchasedStatus")
      }

      return String(localized: "PremiumPurchaseButton")
   }

   private var purchaseButtonPrice: String? {
      guard !store.hasPremiumAccess else { return nil }
      return store.premiumProductPrice
   }

   private var purchaseButtonSubtitle: String? {
      guard !store.hasPremiumAccess else { return nil }
      return purchaseButtonPrice ?? String(localized: "PremiumPriceLoading")
   }

   private var purchaseButtonForeground: Color {
      store.hasPremiumAccess ? LikehateTheme.likeAccent : .white
   }

   private var purchaseButtonBackground: Color {
      if store.hasPremiumAccess {
         return LikehateTheme.likeAccent.opacity(0.18)
      }

      return LikehateTheme.likeAccent
   }

   private var purchaseButtonBorder: Color {
      store.hasPremiumAccess ? LikehateTheme.likeAccent.opacity(0.34) : Color.white.opacity(0.16)
   }

   private var purchaseButtonAccessibilityLabel: String {
      if let purchaseButtonPrice {
         return String.localizedStringWithFormat(String(localized: "PremiumPurchaseButtonWithPriceFormat"), purchaseButtonPrice)
      }

      return purchaseButtonTitle
   }

   private var premiumAnalyticsParameters: FAParameters {
      [
         .personCount: store.persons.count,
         .didBuyRemoveAd: store.didBuyRemoveAd,
         .didBuyPremium: store.didBuyPremium
      ]
   }
}
