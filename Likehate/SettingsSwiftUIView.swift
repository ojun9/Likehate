import FirebaseAnalytics
import SwiftUI

struct SettingsSwiftUIView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var showDeleteConfirmation = false

   var body: some View {
      List {
         Section {
            Button(role: .destructive) {
               Analytics.logEvent("TapDataErasing", parameters: nil)
               HapticsClient.heavy()
               showDeleteConfirmation = true
            } label: {
               Label(NSLocalizedString("deleteErasing", comment: ""), systemImage: "trash")
            }
         }

         Section {
            Button {
               Analytics.logEvent("TapAppReview", parameters: nil)
               HapticsClient.heavy()
               AppReviewClient.requestReview()
            } label: {
               Label(NSLocalizedString("AppRevie", comment: ""), systemImage: "star")
            }

            Link(destination: URL(string: "https://forms.gle/mSEq7WwDz3fZNcqF6")!) {
               Label(NSLocalizedString("ContactUs", comment: ""), systemImage: "envelope")
            }
            .simultaneousGesture(TapGesture().onEnded {
               Analytics.logEvent("TapContacuUs", parameters: nil)
               HapticsClient.light()
            })

            Button {
               Analytics.logEvent("TapCredits", parameters: nil)
               Analytics.logEvent("TapCredit", parameters: nil)
               HapticsClient.medium()
               if let url = URL(string: UIApplication.openSettingsURLString) {
                  UIApplication.shared.open(url)
               }
            } label: {
               Label(NSLocalizedString("Credits", comment: ""), systemImage: "info.circle")
            }
         }
      }
      .navigationTitle(NSLocalizedString("Settings", comment: ""))
      .confirmationDialog(
         NSLocalizedString("doyouwanttodelete", comment: ""),
         isPresented: $showDeleteConfirmation,
         titleVisibility: .visible
      ) {
         Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
            HapticsClient.success()
            store.deleteAll()
         }
         Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {
            HapticsClient.light()
            Analytics.logEvent("delete cannel", parameters: nil)
         }
      } message: {
         Text(NSLocalizedString("thisoperation", comment: ""))
      }
      .onAppear {
         Analytics.logEvent("showSettinVC", parameters: nil)
      }
   }
}
