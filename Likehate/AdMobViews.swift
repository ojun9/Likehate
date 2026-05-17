import GoogleMobileAds
import SwiftUI
import UIKit

enum AdMobUnitID {
#if DEBUG
   static let hateListBanner = "ca-app-pub-3940256099942544/2934735716"
   static let writeHateBanner = "ca-app-pub-3940256099942544/2934735716"
   static let writeHateInterstitial = "ca-app-pub-3940256099942544/4411468910"
#else
   static let hateListBanner = "ca-app-pub-1460017825820383/1086930169"
   static let writeHateBanner = "ca-app-pub-1460017825820383/8035481899"
   static let writeHateInterstitial = "ca-app-pub-1460017825820383/9263543904"
#endif
}

@MainActor
final class LikehateInterstitialAdController: NSObject, ObservableObject, FullScreenContentDelegate {
   private var interstitialAd: InterstitialAd?
   private var isLoading = false

   func load() {
      guard interstitialAd == nil, !isLoading else { return }
      isLoading = true

      Task {
         do {
            interstitialAd = try await InterstitialAd.load(
               with: AdMobUnitID.writeHateInterstitial,
               request: Request()
            )
            interstitialAd?.fullScreenContentDelegate = self
         } catch {
            print("Interstitial load failed: \(error)")
         }

         isLoading = false
      }
   }

   func present() {
      guard let interstitialAd else {
         load()
         return
      }

      let rootViewController = UIApplication.shared.likehateRootViewController
      do {
         try interstitialAd.canPresent(from: rootViewController)
      } catch {
         print("Interstitial cannot present: \(error)")
         load()
         return
      }

      interstitialAd.present(from: rootViewController)
      self.interstitialAd = nil
   }

   func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
      load()
   }

   func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
      print("Interstitial present failed: \(error)")
      load()
   }
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
      }

      func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
         print("AdMob banner failed: \(error)")
      }
   }
}

struct LikehateAdaptiveAdBanner: View {
   let adUnitID: String
   @State private var availableWidth: CGFloat = 320

   var body: some View {
      let adSize = largeAnchoredAdaptiveBanner(width: max(availableWidth, 320))

      LikehateAdBannerView(adUnitID: adUnitID, adSize: adSize)
         .frame(width: adSize.size.width, height: adSize.size.height)
         .frame(maxWidth: .infinity)
         .padding(.bottom, 8)
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
   static var defaultValue: CGFloat = 320

   static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      let next = nextValue()
      if next > 0 {
         value = next
      }
   }
}
