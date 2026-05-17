import FirebaseAnalytics
import SwiftUI

struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
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
               Label {
                  VStack(alignment: .leading, spacing: 3) {
                     Text("AppRevie")
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                     Text("AppReviewSubtitle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                  }
               } icon: {
                  Image(systemName: "star.fill")
                     .foregroundStyle(.yellow)
               }
            }
         }

         Section {
            if !store.didBuyRemoveAd {
               Button {
                  Analytics.logEvent("settings_no_ads_tapped", parameters: settingsAnalyticsParameters)
                  store.purchaseNoAds()
               } label: {
                  if store.isPurchasing {
                     Label {
                        Text("No Ads")
                     } icon: {
                        ProgressView()
                     }
                     .foregroundStyle(.primary)
                  } else {
                     Label("No Ads", systemImage: "nosign")
                        .foregroundStyle(.primary)
                  }
               }
               .disabled(store.isPurchasing)
            }

            Button {
               Analytics.logEvent("settings_restore_tapped", parameters: settingsAnalyticsParameters)
               store.restorePurchases()
            } label: {
               if store.isRestoring {
                  Label {
                     Text("Restore")
                  } icon: {
                     ProgressView()
                  }
                  .foregroundStyle(.primary)
               } else {
                  Label("Restore", systemImage: "arrow.clockwise")
                     .foregroundStyle(.primary)
               }
            }
            .disabled(store.isRestoring)
         }

         Section {
            Toggle(isOn: $isHapticsEnabled) {
               Label("Vibration", systemImage: "iphone.radiowaves.left.and.right")
                  .foregroundStyle(.primary)
            }

            Link(destination: URL(string: "https://forms.gle/mSEq7WwDz3fZNcqF6")!) {
               Label("ContactUs", systemImage: "envelope")
                  .foregroundStyle(.primary)
            }
            .simultaneousGesture(TapGesture().onEnded {
               Analytics.logEvent("TapContacuUs", parameters: nil)
               Analytics.logEvent("settings_contact_tapped", parameters: settingsAnalyticsParameters)
               HapticsClient.light()
            })

            Button {
               Analytics.logEvent("TapDataErasing", parameters: nil)
               Analytics.logEvent("settings_delete_all_tapped", parameters: settingsAnalyticsParameters)
               HapticsClient.heavy()
               showDeleteConfirmation = true
            } label: {
               Label("deleteErasing", systemImage: "trash")
                  .foregroundStyle(.primary)
            }
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
