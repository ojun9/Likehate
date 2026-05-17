import FirebaseAnalytics
import SwiftUI

struct SettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @AppStorage("HapticsEnabled") private var isHapticsEnabled = true
   @State private var showDeleteConfirmation = false

   var body: some View {
      List {
         Section {
            if !store.didBuyRemoveAd {
               Button {
                  store.purchaseNoAds()
               } label: {
                  if store.isPurchasing {
                     Label {
                        Text("No Ads")
                     } icon: {
                        ProgressView()
                     }
                  } else {
                     Label("No Ads", systemImage: "nosign")
                  }
               }
               .disabled(store.isPurchasing)
            }

            Button {
               store.restorePurchases()
            } label: {
               if store.isRestoring {
                  Label {
                     Text("Restore")
                  } icon: {
                     ProgressView()
                  }
               } else {
                  Label("Restore", systemImage: "arrow.clockwise")
               }
            }
            .disabled(store.isRestoring)
         }

         Section {
            Toggle(isOn: $isHapticsEnabled) {
               Label("Vibration", systemImage: "iphone.radiowaves.left.and.right")
            }
         }

         Section {
            Button(role: .destructive) {
               Analytics.logEvent("TapDataErasing", parameters: nil)
               HapticsClient.heavy()
               showDeleteConfirmation = true
            } label: {
               Label("deleteErasing", systemImage: "trash")
            }
         }

         Section {
            Button {
               Analytics.logEvent("TapAppReview", parameters: nil)
               HapticsClient.heavy()
               AppReviewClient.requestReview()
            } label: {
               Label("AppRevie", systemImage: "star")
            }

            Link(destination: URL(string: "https://forms.gle/mSEq7WwDz3fZNcqF6")!) {
               Label("ContactUs", systemImage: "envelope")
            }
            .simultaneousGesture(TapGesture().onEnded {
               Analytics.logEvent("TapContacuUs", parameters: nil)
               HapticsClient.light()
            })

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
            HapticsClient.success()
            store.deleteAll()
         }
         Button(String(localized: "cancel"), role: .cancel) {
            HapticsClient.light()
            Analytics.logEvent("delete cannel", parameters: nil)
         }
      } message: {
         Text("thisoperation")
      }
      .onAppear {
         Analytics.logEvent("showSettinVC", parameters: nil)
      }
   }
}
