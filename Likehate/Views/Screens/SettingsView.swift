import SwiftUI
#if DEBUG
import RevenueCat
#endif

struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @AppStorage("HapticsEnabled") private var isHapticsEnabled = true
   @State private var showDeleteConfirmation = false
   @State private var showsRevenueCatDebug = false

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      List {
         Section {
            Button {
               FAAnalytics.log(.track(.settingsAppReviewTapped, parameters: settingsAnalyticsParameters))
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
            NavigationLink {
               PremiumView()
            } label: {
               SettingsActionRow(
                  iconName: store.hasPremiumAccess ? "checkmark.seal.fill" : "sparkles",
                  title: "PremiumTitle",
                  subtitle: store.hasPremiumAccess ? "PremiumPurchasedStatus" : "PremiumSettingsSubtitle",
                  iconColor: store.hasPremiumAccess ? LikehateTheme.likeAccent : .yellow,
                  titleWeight: .bold
               )
            }
            .simultaneousGesture(TapGesture().onEnded {
               FAAnalytics.log(.track(.settingsPremiumTapped, parameters: settingsAnalyticsParameters))
            })

            Button {
               FAAnalytics.log(.track(.settingsRestoreTapped, parameters: settingsAnalyticsParameters))
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
               FAAnalytics.log(.track(.settingsDeleteAllTapped, parameters: settingsAnalyticsParameters))
               HapticsClient.heavy()
               showDeleteConfirmation = true
            } label: {
               SettingsActionRow(iconName: "trash", title: "deleteErasing")
            }
            .buttonStyle(.plain)
         }

         #if DEBUG
         Section("DebugSectionTitle") {
            Button {
               FAAnalytics.log(.track(.settingsRevenueCatDebugTapped, parameters: settingsAnalyticsParameters))
               showsRevenueCatDebug = true
            } label: {
               SettingsActionRow(
                  iconName: "creditcard",
                  title: "RevenueCatDebugTitle",
                  subtitle: "RevenueCatDebugSubtitle",
                  iconColor: LikehateTheme.likeAccent
               )
            }
            .buttonStyle(.plain)

            Toggle(
               isOn: Binding(
                  get: { store.isAppStoreScreenshotModeEnabled },
                  set: { store.setAppStoreScreenshotModeEnabled($0) }
               )
            ) {
               SettingsActionRow(
                  iconName: "camera.viewfinder",
                  title: "AppStoreScreenshotModeTitle",
                  subtitle: "AppStoreScreenshotModeSubtitle",
                  iconColor: .orange
               )
            }
         }
         #endif
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
            FAAnalytics.log(.track(.settingsDeleteAllConfirmed, parameters: settingsAnalyticsParameters))
            HapticsClient.success()
            store.deleteAll()
         }
         Button(String(localized: "cancel"), role: .cancel) {
            HapticsClient.light()
            FAAnalytics.log(.track(.settingsDeleteAllCancelled, parameters: settingsAnalyticsParameters))
         }
      } message: {
         Text("DeleteAllConfirmationMessage")
      }
      .onAppear {
         FAAnalytics.log(.screenView(.settings, parameters: settingsAnalyticsParameters))
      }
      .onChange(of: store.animationEnabled) { _, isEnabled in
         FAAnalytics.log(.track(.settingsAnimationChanged, parameters: settingsAnalyticsParameters.merging([
            "animation_enabled": isEnabled
         ]) { _, new in new }))
      }
      .onChange(of: isHapticsEnabled) { _, isEnabled in
         FAAnalytics.log(.track(.settingsHapticsChanged, parameters: settingsAnalyticsParameters.merging([
            "is_haptics_enabled": isEnabled
         ]) { _, new in new }))
      }
      .onChange(of: store.textSize) { _, textSize in
         FAAnalytics.log(.track(.settingsTextSizeChanged, parameters: settingsAnalyticsParameters.merging([
            "text_size": textSize.rawValue
         ]) { _, new in new }))
      }
      .debugRevenueCatOverlayIfDebug(isPresented: $showsRevenueCatDebug)
   }

   private var settingsAnalyticsParameters: [String: Any] {
      [
         "like_count": store.likes.count,
         "hate_count": store.hates.count,
         "total_count": store.likes.count + store.hates.count,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "did_buy_premium": store.didBuyPremium,
         "animation_enabled": store.animationEnabled,
         "is_haptics_enabled": isHapticsEnabled,
         "text_size": store.textSize.rawValue
      ]
   }
}

private extension View {
   @ViewBuilder
   func debugRevenueCatOverlayIfDebug(isPresented: Binding<Bool>) -> some View {
      #if DEBUG
      debugRevenueCatOverlay(isPresented: isPresented)
      #else
      self
      #endif
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
                  FAAnalytics.log(.track(.settingsTextSizeSelected, parameters: [
                     "text_size": textSize.rawValue,
                     "previous_text_size": store.textSize.rawValue
                  ]))
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
      .onAppear {
         FAAnalytics.log(.screenView(.textSizeSettings, parameters: [
            "text_size": store.textSize.rawValue
         ]))
      }
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
