import SwiftUI

/// アプリ設定、購入復元、デバッグ機能への入口をまとめた画面。
struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @AppStorage("HapticsEnabled") private var isHapticsEnabled = true
   @State private var showDeleteConfirmation = false
   @State private var isShowingPremium = false
   @State private var showsRevenueCatDebug = false

   let onOpenDebugOnboarding: () -> Void

   init(onOpenDebugOnboarding: @escaping () -> Void = {}) {
      self.onOpenDebugOnboarding = onOpenDebugOnboarding
   }

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
            Button {
               FAAnalytics.log(.track(.settingsPremiumTapped, parameters: settingsAnalyticsParameters))
               isShowingPremium = true
            } label: {
               SettingsActionRow(
                  iconName: store.hasPremiumAccess ? "checkmark.seal.fill" : "sparkles",
                  title: "PremiumTitle",
                  subtitle: store.hasPremiumAccess ? "PremiumPurchasedStatus" : "PremiumSettingsSubtitle",
                  iconColor: store.hasPremiumAccess ? LikehateTheme.likeAccent : .yellow,
                  titleWeight: .bold
               )
            }
            .buttonStyle(.plain)

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

         Section {
            NavigationLink {
               LicenseView()
            } label: {
               SettingsActionRow(iconName: "doc.text.magnifyingglass", title: "License")
            }

            SettingsVersionRow(versionText: appVersionDisplayText)
         }

         #if DEBUG
         Section("DebugSectionTitle") {
            Button {
               HapticsClient.light()
               onOpenDebugOnboarding()
            } label: {
               SettingsActionRow(
                  iconName: "sparkles",
                  title: "OnboardingDebugTitle",
                  subtitle: "OnboardingDebugSubtitle",
                  iconColor: LikehateTheme.sparkleAccent
               )
            }
            .buttonStyle(.plain)

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
            .animationEnabled: isEnabled
         ])))
      }
      .onChange(of: isHapticsEnabled) { _, isEnabled in
         FAAnalytics.log(.track(.settingsHapticsChanged, parameters: settingsAnalyticsParameters.merging([
            .isHapticsEnabled: isEnabled
         ])))
      }
      .onChange(of: store.textSize) { _, textSize in
         FAAnalytics.log(.track(.settingsTextSizeChanged, parameters: settingsAnalyticsParameters.merging([
            .textSize: textSize.rawValue
         ])))
      }
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .debugRevenueCatOverlayIfDebug(isPresented: $showsRevenueCatDebug)
   }

   private var settingsAnalyticsParameters: FAParameters {
      [
         .likeCount: store.likes.count,
         .hateCount: store.hates.count,
         .totalCount: store.likes.count + store.hates.count,
         .didBuyRemoveAd: store.didBuyRemoveAd,
         .didBuyPremium: store.didBuyPremium,
         .animationEnabled: store.animationEnabled,
         .isHapticsEnabled: isHapticsEnabled,
         .textSize: store.textSize.rawValue
      ]
   }

   private var appVersionDisplayText: String {
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
      let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
      return "\(version)(\(build))"
   }
}
