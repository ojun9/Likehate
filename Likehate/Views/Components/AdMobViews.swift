import FirebaseAnalytics
import GoogleMobileAds
import SwiftUI
import UIKit

enum AdMobUnitID: Sendable {
    #if DEBUG
   static let itemListBanner = "ca-app-pub-3940256099942544/2934735716"
    #else
   static let itemListBanner = "ca-app-pub-1460017825820383/1086930169"
    #endif
}

struct LikehateAdBannerView: UIViewRepresentable {
   let adSize: AdSize
   let adUnitID: String

   init(adUnitID: String, adSize: AdSize) {
      self.adUnitID = adUnitID
      self.adSize = adSize
   }

   func makeUIView(context: Context) -> BannerView {
      let banner = BannerView(adSize: adSize)
      banner.adUnitID = adUnitID
      banner.delegate = context.coordinator
      banner.rootViewController = UIApplication.shared.likehateRootViewController
      banner.load(Request())
      return banner
   }

   func updateUIView(_ uiView: BannerView, context: Context) {
      uiView.adSize = adSize
      uiView.rootViewController = UIApplication.shared.likehateRootViewController
   }

   func makeCoordinator() -> Coordinator {
      Coordinator(adUnitID: adUnitID)
   }

   final class Coordinator: NSObject, BannerViewDelegate {
      init(adUnitID: String) {
         self.adUnitID = adUnitID
      }

      private let adUnitID: String

      func bannerViewDidReceiveAd(_ bannerView: BannerView) {
         print("AdMob banner loaded: \(adUnitID)")
         Analytics.logEvent("ad_banner_loaded", parameters: [
            "placement": "item_list"
         ])
      }

      func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
         let nsError = error as NSError
         print("AdMob banner failed: \(error)")
         Analytics.logEvent("ad_banner_failed", parameters: [
            "placement": "item_list",
            "error_domain": nsError.domain,
            "error_code": nsError.code
         ])
      }
   }
}

struct LikehateAdaptiveAdBanner: View {
   let adUnitID: String
   @State private var availableWidth: CGFloat = 320

   var body: some View {
      let adSize = largePortraitAnchoredAdaptiveBanner(width: max(availableWidth, 320))

      LikehateAdBannerView(adUnitID: adUnitID, adSize: adSize)
         .frame(width: adSize.size.width, height: adSize.size.height)
         .frame(maxWidth: .infinity)
         .onAppear {
            Analytics.logEvent("ad_banner_container_appeared", parameters: [
               "placement": "item_list",
               "available_width": availableWidth
            ])
         }
         .background {
            GeometryReader { proxy in
               Color.clear
                  .preference(key: BannerWidthPreferenceKey.self, value: proxy.size.width)
            }
         }
         .onPreferenceChange(BannerWidthPreferenceKey.self) { width in
            if width > 0 {
               availableWidth = width
            }
         }
         .frame(height: adSize.size.height + 8)
         .background(Color(.systemBackground))
   }
}

private struct BannerWidthPreferenceKey: PreferenceKey {
   static let defaultValue: CGFloat = 320

   static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      let next = nextValue()
      if next > 0 {
         value = next
      }
   }
}
