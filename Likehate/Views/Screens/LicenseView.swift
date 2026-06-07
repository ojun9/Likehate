import LicenseList
import SwiftUI

struct LicenseView: View {
   var body: some View {
      LicenseListView()
         .licenseViewStyle(.plain)
         .navigationTitle("License")
         .navigationBarTitleDisplayMode(.inline)
         .onAppear {
            FAAnalytics.log(.screenView(.license, parameters: [:]))
         }
   }
}
