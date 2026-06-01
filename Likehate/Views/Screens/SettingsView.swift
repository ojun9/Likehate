import FirebaseAnalytics
import SwiftUI

struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @AppStorage("HapticsEnabled") private var isHapticsEnabled = true
   @State private var showDeleteConfirmation = false

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

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
            } else {
               SettingsActionRow(iconName: "checkmark.seal", title: "AdsRemovedStatus")
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
            NavigationLink {
               TextSizeSettingsView()
            } label: {
               SettingsActionRow(iconName: "textformat.size", title: "TextSizeSettingTitle", value: store.textSize.title)
            }

            Toggle(isOn: $store.animationEnabled) {
               SettingsActionRow(iconName: "sparkles", title: "AnimationSettingTitle")
            }

            Toggle(isOn: $isHapticsEnabled) {
               SettingsActionRow(iconName: "iphone.radiowaves.left.and.right", title: "Vibration")
            }

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
      .font(typography.bodyRegular)
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
         String(localized: "DeleteAllConfirmationTitle"),
         isPresented: $showDeleteConfirmation,
         titleVisibility: .visible
      ) {
         Button(String(localized: "DeleteAllConfirmButton"), role: .destructive) {
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
         Text("DeleteAllConfirmationMessage")
      }
      .onAppear {
         Analytics.logEvent("showSettinVC", parameters: settingsAnalyticsParameters)
         Analytics.logEvent("screen_view_settings", parameters: settingsAnalyticsParameters)
      }
      .onChange(of: store.animationEnabled) { _, isEnabled in
         Analytics.logEvent("settings_animation_changed", parameters: settingsAnalyticsParameters.merging([
            "animation_enabled": isEnabled
         ]) { _, new in new })
      }
      .onChange(of: isHapticsEnabled) { _, isEnabled in
         Analytics.logEvent("settings_haptics_changed", parameters: settingsAnalyticsParameters.merging([
            "is_haptics_enabled": isEnabled
         ]) { _, new in new })
      }
      .onChange(of: store.textSize) { _, textSize in
         Analytics.logEvent("settings_text_size_changed", parameters: settingsAnalyticsParameters.merging([
            "text_size": textSize.rawValue
         ]) { _, new in new })
      }
   }

   private var settingsAnalyticsParameters: [String: Any] {
      [
         "like_count": store.likes.count,
         "hate_count": store.hates.count,
         "total_count": store.likes.count + store.hates.count,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "animation_enabled": store.animationEnabled,
         "is_haptics_enabled": isHapticsEnabled,
         "text_size": store.textSize.rawValue
      ]
   }
}

private struct TextSizeSettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      List {
         Section {
            ForEach(AppTextSize.allCases) { textSize in
               Button {
                  store.textSize = textSize
               } label: {
                  HStack(spacing: 12) {
                     Text(textSize.title)
                        .font(typography.body)
                        .foregroundStyle(.primary)

                     Spacer()

                     if store.textSize == textSize {
                        Image(systemName: "checkmark")
                           .font(typography.subtext)
                           .foregroundStyle(LikehateTheme.likeAccent)
                     }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .frame(minHeight: layout.rowMinHeight)
                  .contentShape(Rectangle())
               }
               .contentShape(Rectangle())
               .buttonStyle(.plain)
            }
         } footer: {
            Text("TextSizeHelpText")
               .font(typography.subtext)
         }
      }
      .navigationTitle("TextSizeSettingTitle")
      .navigationBarTitleDisplayMode(.inline)
   }
}

private struct SettingsActionRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let iconName: String
   let title: LocalizedStringKey
   var subtitle: LocalizedStringKey?
   var value: LocalizedStringKey?
   var iconColor: Color = .primary
   var titleWeight: Font.Weight = .regular

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         Image(systemName: iconName)
            .font(typography.body)
            .foregroundStyle(iconColor)
            .frame(width: 24, alignment: .center)

         VStack(alignment: .leading, spacing: 3) {
            Text(title)
               .font(typography.bodyRegular)
               .fontWeight(titleWeight)
               .foregroundStyle(.primary)

            if let subtitle {
               Text(subtitle)
                  .font(typography.subtext)
                  .foregroundStyle(.secondary)
            }
         }

         Spacer(minLength: 0)

         if let value {
            Text(value)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
         }
      }
      .frame(minHeight: layout.rowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}

private struct SettingsProgressRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: LocalizedStringKey

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         ProgressView()
            .frame(width: 24, alignment: .center)

         Text(title)
            .font(typography.bodyRegular)
            .foregroundStyle(.primary)

         Spacer(minLength: 0)
      }
      .frame(minHeight: layout.rowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}
