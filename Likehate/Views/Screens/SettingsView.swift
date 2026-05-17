import FirebaseAnalytics
import SwiftUI

struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.openURL) private var openURL
   @AppStorage("HapticsEnabled") private var isHapticsEnabled = true
   @State private var showDeleteConfirmation = false

   var body: some View {
      List {
         Section {
            Button {
               Analytics.logEvent("TapAppReview", parameters: nil)
               Analytics.logEvent("settings_app_review_tapped", parameters: settingsAnalyticsParameters)
               HapticsClient.heavy()
               AppReviewClient.requestReview()
            } label: {
               SettingsActionRow(
                  iconName: "star.fill",
                  title: "AppRevie",
                  subtitle: "AppReviewSubtitle",
                  iconColor: .yellow,
                  titleWeight: .bold
               )
            }
            .buttonStyle(.plain)
         }

         Section {
            if !store.didBuyRemoveAd {
               Button {
                  Analytics.logEvent("settings_no_ads_tapped", parameters: settingsAnalyticsParameters)
                  store.purchaseNoAds()
               } label: {
                  if store.isPurchasing {
                     SettingsProgressRow(title: "No Ads")
                  } else {
                     SettingsActionRow(iconName: "nosign", title: "No Ads")
                  }
               }
               .disabled(store.isPurchasing)
               .buttonStyle(.plain)
            }

            Button {
               Analytics.logEvent("settings_restore_tapped", parameters: settingsAnalyticsParameters)
               store.restorePurchases()
            } label: {
               if store.isRestoring {
                  SettingsProgressRow(title: "Restore")
               } else {
                  SettingsActionRow(iconName: "arrow.clockwise", title: "Restore")
               }
            }
            .disabled(store.isRestoring)
            .buttonStyle(.plain)
         }

         Section {
            Toggle(isOn: $isHapticsEnabled) {
               SettingsActionRow(iconName: "iphone.radiowaves.left.and.right", title: "Vibration")
            }

            Button {
               Analytics.logEvent("TapContacuUs", parameters: nil)
               Analytics.logEvent("settings_contact_tapped", parameters: settingsAnalyticsParameters)
               HapticsClient.light()
               openURL(URL(string: "https://forms.gle/mSEq7WwDz3fZNcqF6")!)
            } label: {
               SettingsActionRow(iconName: "envelope", title: "ContactUs")
            }
            .buttonStyle(.plain)

            Button {
               Analytics.logEvent("TapDataErasing", parameters: nil)
               Analytics.logEvent("settings_delete_all_tapped", parameters: settingsAnalyticsParameters)
               HapticsClient.heavy()
               showDeleteConfirmation = true
            } label: {
               SettingsActionRow(iconName: "trash", title: "deleteErasing")
            }
            .buttonStyle(.plain)
         }
      }
      .navigationTitle("SettingsTitle")
      .navigationBarTitleDisplayMode(.inline)
      .alert(item: $store.purchaseMessage) { message in
         Alert(
            title: Text(message.title),
            message: Text(message.message),
            dismissButton: .default(Text("OK"))
         )
      }
      .confirmationDialog(
         String(localized: "doyouwanttodelete"),
         isPresented: $showDeleteConfirmation,
         titleVisibility: .visible
      ) {
         Button(String(localized: "delete"), role: .destructive) {
            Analytics.logEvent("settings_delete_all_confirmed", parameters: settingsAnalyticsParameters)
            HapticsClient.success()
            store.deleteAll()
         }
         Button(String(localized: "cancel"), role: .cancel) {
            HapticsClient.light()
            Analytics.logEvent("delete cannel", parameters: nil)
            Analytics.logEvent("settings_delete_all_cancelled", parameters: settingsAnalyticsParameters)
         }
      } message: {
         Text("thisoperation")
      }
      .onAppear {
         Analytics.logEvent("showSettinVC", parameters: settingsAnalyticsParameters)
         Analytics.logEvent("screen_view_settings", parameters: settingsAnalyticsParameters)
      }
      .onChange(of: isHapticsEnabled) { _, isEnabled in
         Analytics.logEvent("settings_haptics_changed", parameters: settingsAnalyticsParameters.merging([
            "is_haptics_enabled": isEnabled
         ]) { _, new in new })
      }
   }

   private var settingsAnalyticsParameters: [String: Any] {
      [
         "like_count": store.likes.count,
         "hate_count": store.hates.count,
         "total_count": store.likes.count + store.hates.count,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "is_haptics_enabled": isHapticsEnabled
      ]
   }
}

private struct SettingsActionRow: View {
   let iconName: String
   let title: LocalizedStringKey
   var subtitle: LocalizedStringKey?
   var iconColor: Color = .primary
   var titleWeight: Font.Weight = .regular

   var body: some View {
      HStack(spacing: 12) {
         Image(systemName: iconName)
            .font(.body)
            .foregroundStyle(iconColor)
            .frame(width: 24, alignment: .center)

         VStack(alignment: .leading, spacing: 3) {
            Text(title)
               .fontWeight(titleWeight)
               .foregroundStyle(.primary)

            if let subtitle {
               Text(subtitle)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
            }
         }

         Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}

private struct SettingsProgressRow: View {
   let title: LocalizedStringKey

   var body: some View {
      HStack(spacing: 12) {
         ProgressView()
            .frame(width: 24, alignment: .center)

         Text(title)
            .foregroundStyle(.primary)

         Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}
