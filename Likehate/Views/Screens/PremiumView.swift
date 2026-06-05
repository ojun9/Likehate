import FirebaseAnalytics
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
            VStack(alignment: .leading, spacing: 12) {
               Text("PremiumHeroTitle")
                  .font(typography.sectionTitle)
                  .foregroundStyle(.primary)
                  .lineLimit(3)

               Text("PremiumHeroMessage")
                  .font(typography.body)
                  .foregroundStyle(.secondary)
                  .lineSpacing(4)

               Text("PremiumFreeLimitMessage")
                  .font(typography.body)
                  .foregroundStyle(.secondary)
                  .lineSpacing(4)

               Text("PremiumUpgradeMessage")
                  .font(typography.body)
                  .foregroundStyle(.secondary)
                  .lineSpacing(4)

               Text("PremiumOneTimeNote")
                  .font(typography.subtext)
                  .fontWeight(.bold)
                  .foregroundStyle(LikehateTheme.likeAccent)
            }
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 14) {
               PremiumBenefitRow(iconName: "person.3.fill", title: "PremiumBenefitPeople")
               PremiumBenefitRow(iconName: "rectangle.badge.xmark", title: "PremiumBenefitNoAds")
               PremiumBenefitRow(iconName: "checkmark.seal.fill", title: "PremiumBenefitLifetime")
            }
            .padding(layout.cardPadding)
            .background(LikehateTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
               RoundedRectangle(cornerRadius: 22, style: .continuous)
                  .stroke(LikehateTheme.border, lineWidth: 1)
            }

            VStack(spacing: 12) {
               Button {
                  Analytics.logEvent("premium_purchase_button_tapped", parameters: premiumAnalyticsParameters)
                  store.purchasePremium()
               } label: {
                  HStack(spacing: 8) {
                     if store.isPurchasing {
                        ProgressView()
                           .tint(.white)
                     }

                     Text(verbatim: purchaseButtonTitle)
                        .font(typography.button)
                        .fontWeight(.bold)
                  }
                  .frame(maxWidth: .infinity)
                  .frame(minHeight: 56)
               }
               .buttonStyle(.borderedProminent)
               .tint(LikehateTheme.likeAccent)
               .disabled(store.isPurchasing || store.hasPremiumAccess)

               Button {
                  Analytics.logEvent("premium_restore_tapped", parameters: premiumAnalyticsParameters)
                  store.restorePurchases()
               } label: {
                  if store.isRestoring {
                     HStack(spacing: 8) {
                        ProgressView()
                        Text("Restore")
                     }
                     .font(typography.button)
                     .frame(maxWidth: .infinity)
                     .frame(minHeight: 50)
                  } else {
                     Text("PremiumRestoreButton")
                        .font(typography.button)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                  }
               }
               .buttonStyle(.bordered)
               .tint(LikehateTheme.likeAccent)
               .disabled(store.isRestoring)

               Button {
                  dismiss()
               } label: {
                  Text("PremiumCloseButton")
                     .font(typography.button)
                     .foregroundStyle(.secondary)
                     .frame(maxWidth: .infinity)
                     .frame(minHeight: 48)
               }
               .buttonStyle(.plain)
            }
         }
         .padding(.horizontal, layout.screenPadding)
         .padding(.bottom, layout.sectionSpacing)
      }
      .background(LikehateTheme.background.ignoresSafeArea())
      .navigationTitle("PremiumTitle")
      .navigationBarTitleDisplayMode(.inline)
      .alert(item: $store.purchaseMessage) { message in
         Alert(
            title: Text(message.title),
            message: Text(message.message),
            dismissButton: .default(Text("OK"))
         )
      }
      .onAppear {
         store.loadPremiumProductInfo()
         Analytics.logEvent("screen_view_premium", parameters: premiumAnalyticsParameters)
      }
   }

   private var purchaseButtonTitle: String {
      if store.hasPremiumAccess {
         return String(localized: "PremiumPurchasedStatus")
      }

      if let premiumProductPrice = store.premiumProductPrice {
         return String.localizedStringWithFormat(String(localized: "PremiumPurchaseButtonWithPriceFormat"), premiumProductPrice)
      }

      return String(localized: "PremiumPurchaseButton")
   }

   private var premiumAnalyticsParameters: [String: Any] {
      [
         "person_count": store.persons.count,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "did_buy_premium": store.didBuyPremium
      ]
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
