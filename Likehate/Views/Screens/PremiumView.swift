import SwiftUI

struct PremiumView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
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
                  opacity: 0.07,
                  borderOpacity: 0.2
               )
            }
         }
         .padding(.horizontal, layout.screenPadding)
         .padding(.bottom, layout.sectionSpacing + 154)
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
            FAAnalytics.log(.track(.premiumPurchaseButtonTapped, parameters: premiumAnalyticsParameters))
            store.purchasePremium()
         } label: {
            VStack(spacing: 4) {
               HStack(spacing: 8) {
                  if store.isPurchasing {
                     ProgressView()
                        .tint(.white)
                  }

                  Text(verbatim: purchaseButtonTitle)
                     .font(typography.button)
                     .fontWeight(.bold)
               }

               Text(verbatim: purchaseButtonPrice ?? String(localized: "PremiumPriceLoading"))
                  .font(typography.subtext)
                  .fontWeight(.semibold)
                  .foregroundStyle(.white.opacity(0.92))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
         }
         .buttonStyle(.borderedProminent)
         .tint(LikehateTheme.likeAccent)
         .disabled(store.isPurchasing || store.hasPremiumAccess)
         .accessibilityLabel(Text(verbatim: purchaseButtonAccessibilityLabel))

         HStack(spacing: 14) {
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

            Button {
               dismiss()
            } label: {
               Text("PremiumCloseButton")
                  .font(typography.subtext)
                  .fontWeight(.semibold)
                  .foregroundStyle(.secondary)
                  .frame(maxWidth: .infinity)
                  .frame(minHeight: 42)
            }
            .buttonStyle(.plain)
         }
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

private struct PremiumHeroPanel: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      VStack(alignment: .leading, spacing: 18) {
         HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("PremiumBadge")
         }
         .font(typography.subtext)
         .fontWeight(.bold)
         .foregroundStyle(LikehateTheme.likeAccent)
         .padding(.horizontal, 12)
         .padding(.vertical, 7)
         .background(LikehateTheme.likeAccent.opacity(0.13), in: Capsule())

         VStack(alignment: .leading, spacing: 10) {
            Text("PremiumHeroTitle")
               .font(typography.sectionTitle)
               .foregroundStyle(.primary)
               .lineLimit(3)

            Text("PremiumUpgradeMessage")
               .font(typography.body)
               .foregroundStyle(.secondary)
               .lineSpacing(4)
         }

         HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
               .font(typography.body)
               .foregroundStyle(LikehateTheme.hateAccent)
               .frame(width: 30, height: 30)
               .background(LikehateTheme.hateAccent.opacity(0.12), in: Circle())

            Text("PremiumFreeLimitMessage")
               .font(typography.subtext)
               .foregroundStyle(.secondary)
               .lineSpacing(3)

            Spacer(minLength: 0)
         }
         .padding(14)
         .background(LikehateTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      }
      .padding(layout.cardPadding + 4)
      .background(LikehateTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
      .overlay {
         RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(LikehateTheme.likeAccent.opacity(0.24), lineWidth: 1)
      }
   }
}

private struct PremiumPlanComparison: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let price: String?

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      VStack(alignment: .leading, spacing: 12) {
         Text("PremiumComparisonTitle")
            .font(typography.cardTitle)
            .foregroundStyle(.primary)

         VStack(spacing: 10) {
            PremiumPlanRow(
               iconName: "lock.fill",
               title: "PremiumFreePlanTitle",
               message: "PremiumFreePlanMessage",
               badge: "PremiumFreePlanBadge",
               accent: .secondary,
               isEmphasized: false
            )

            PremiumPlanRow(
               iconName: "checkmark.seal.fill",
               title: "PremiumPaidPlanTitle",
               message: "PremiumPaidPlanMessage",
               badgeText: price ?? String(localized: "PremiumPriceLoading"),
               accent: LikehateTheme.likeAccent,
               isEmphasized: true
            )
         }
      }
      .padding(layout.cardPadding)
      .background {
         PremiumGlassBackground(
            cornerRadius: 22,
            tint: LikehateTheme.sparkleAccent,
            opacity: 0.055,
            borderOpacity: 0.16
         )
      }
   }
}

private struct PremiumPlanRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let iconName: String
   let title: LocalizedStringKey
   let message: LocalizedStringKey
   let badge: LocalizedStringKey?
   let badgeText: String?
   let accent: Color
   let isEmphasized: Bool

   init(iconName: String, title: LocalizedStringKey, message: LocalizedStringKey, badge: LocalizedStringKey, accent: Color, isEmphasized: Bool) {
      self.iconName = iconName
      self.title = title
      self.message = message
      self.badge = badge
      self.badgeText = nil
      self.accent = accent
      self.isEmphasized = isEmphasized
   }

   init(iconName: String, title: LocalizedStringKey, message: LocalizedStringKey, badgeText: String, accent: Color, isEmphasized: Bool) {
      self.iconName = iconName
      self.title = title
      self.message = message
      self.badge = nil
      self.badgeText = badgeText
      self.accent = accent
      self.isEmphasized = isEmphasized
   }

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(alignment: .top, spacing: 12) {
         Image(systemName: iconName)
            .font(typography.body)
            .foregroundStyle(accent)
            .frame(width: 34, height: 34)
            .background(accent.opacity(isEmphasized ? 0.16 : 0.08), in: Circle())

         VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
               Text(title)
                  .font(typography.body)
                  .fontWeight(.bold)
                  .foregroundStyle(.primary)

               Spacer(minLength: 0)

               if let badge {
                  Text(badge)
                     .font(typography.subtext)
                     .fontWeight(.bold)
                     .foregroundStyle(.secondary)
                     .lineLimit(1)
               } else if let badgeText {
                  Text(verbatim: badgeText)
                     .font(typography.subtext)
                     .fontWeight(.bold)
                     .foregroundStyle(accent)
                     .lineLimit(1)
               }
            }

            Text(message)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
               .lineSpacing(3)
         }
      }
      .padding(14)
      .background {
         PremiumGlassBackground(
            cornerRadius: 16,
            tint: accent,
            opacity: isEmphasized ? 0.12 : 0.045,
            borderOpacity: isEmphasized ? 0.24 : 0.14
         )
      }
   }
}

private struct PremiumBenefitRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let iconName: String
   let title: LocalizedStringKey

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(spacing: 12) {
         Image(systemName: iconName)
            .font(typography.body)
            .foregroundStyle(LikehateTheme.likeAccent)
            .frame(width: 28, height: 28)
            .background(LikehateTheme.likeAccent.opacity(0.12), in: Circle())

         Text(title)
            .font(typography.body)
            .foregroundStyle(.primary)
            .lineLimit(2)

         Spacer(minLength: 0)
      }
   }
}

private struct PremiumGlassBackground: View {
   let cornerRadius: CGFloat
   let tint: Color
   let opacity: Double
   let borderOpacity: Double

   var body: some View {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
         .fill(.ultraThinMaterial)
         .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
               .fill(tint.opacity(opacity))
         }
         .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
               .strokeBorder(
                  LinearGradient(
                     colors: [
                        Color.white.opacity(borderOpacity),
                        tint.opacity(borderOpacity * 0.7),
                        Color.white.opacity(borderOpacity * 0.35)
                     ],
                     startPoint: .topLeading,
                     endPoint: .bottomTrailing
                  ),
                  lineWidth: 1
               )
         }
   }
}
