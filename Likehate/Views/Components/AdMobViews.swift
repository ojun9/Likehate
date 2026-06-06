import GoogleMobileAds
import SwiftUI
import UIKit

/// 一覧系画面で使うAdMob広告ユニットID。
private enum AdMobUnitID: Sendable {
    #if DEBUG
   static let itemListBanner = "ca-app-pub-3940256099942544/2934735716"
    #else
   static let itemListBanner = "ca-app-pub-1460017825820383/1086930169"
    #endif
}

/// 広告表示場所を分析イベントで区別するための識別子。
enum ListAdPlacement: String, Sendable {
   case itemList = "item_list"
   case comparisonCategoryDetail = "comparison_category_detail"
}

/// Google Mobile AdsのバナーViewをSwiftUIで扱うためのラッパー。
struct LikehateAdBannerView: UIViewRepresentable {
   let adSize: AdSize
   let adUnitID: String
   let placement: ListAdPlacement

   init(adUnitID: String, adSize: AdSize, placement: ListAdPlacement) {
      self.adUnitID = adUnitID
      self.adSize = adSize
      self.placement = placement
   }

   func makeUIView(context: Context) -> BannerView {
      let banner = BannerView(adSize: adSize)
      banner.adUnitID = adUnitID
      banner.delegate = context.coordinator
      banner.rootViewController = UIApplication.shared.likehateRootViewController
      banner.clipsToBounds = true
      banner.load(Request())
      return banner
   }

   func updateUIView(_ uiView: BannerView, context: Context) {
      uiView.adSize = adSize
      uiView.rootViewController = UIApplication.shared.likehateRootViewController
      uiView.clipsToBounds = true
   }

   func makeCoordinator() -> Coordinator {
      Coordinator(adUnitID: adUnitID, placement: placement)
   }

   /// AdMobバナーの読み込み結果を分析イベントへ変換するデリゲート。
   final class Coordinator: NSObject, BannerViewDelegate {
      init(adUnitID: String, placement: ListAdPlacement) {
         self.adUnitID = adUnitID
         self.placement = placement
      }

      private let adUnitID: String
      private let placement: ListAdPlacement

      func bannerViewDidReceiveAd(_ bannerView: BannerView) {
         print("AdMob banner loaded: \(adUnitID)")
         FAAnalytics.log(.track(.adBannerLoaded, parameters: [
            .placement: placement.rawValue
         ]))
      }

      func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
         let nsError = error as NSError
         print("AdMob banner failed: \(error)")
         FAAnalytics.log(.track(.adBannerFailed, parameters: [
            .placement: placement.rawValue,
            .errorDomain: nsError.domain,
            .errorCode: nsError.code
         ]))
      }
   }
}

/// 画面幅に合わせたインライン適応バナーを表示するView。
struct LikehateAdaptiveAdBanner: View {
   let adUnitID: String
   let placement: ListAdPlacement
   @State private var availableWidth: CGFloat = 320

   var body: some View {
      let adSize = inlineAdaptiveBanner(width: max(availableWidth, 320), maxHeight: 72)

      LikehateAdBannerView(adUnitID: adUnitID, adSize: adSize, placement: placement)
         .frame(width: adSize.size.width, height: adSize.size.height)
         .frame(maxWidth: .infinity)
         .clipped()
         .onAppear {
            FAAnalytics.log(.track(.adBannerContainerAppeared, parameters: [
               .placement: placement.rawValue,
               .availableWidth: availableWidth
            ]))
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
         .background(Color.clear)
   }
}

/// 一覧系画面で、広告表示条件を満たす場合だけバナーを差し込むView。
struct ConditionalListAdBanner: View {
   @EnvironmentObject private var store: LikeHateStore

   let placement: ListAdPlacement
   let hasItems: Bool
   var topPadding: CGFloat = 24
   var bottomPadding: CGFloat = 16

   var body: some View {
      if AdDisplayPolicy(adsRemoved: store.appSettings.adsRemoved, isPremium: store.appSettings.isPremium).showsListAd(hasItems: hasItems) {
         ListAdBanner(placement: placement, topPadding: topPadding, bottomPadding: bottomPadding)
      }
   }
}

/// 一覧コンテンツの外側に置く広告表示本体。
private struct ListAdBanner: View {
   let placement: ListAdPlacement
   let topPadding: CGFloat
   let bottomPadding: CGFloat

   var body: some View {
      LikehateAdaptiveAdBanner(adUnitID: AdMobUnitID.itemListBanner, placement: placement)
         .padding(.top, topPadding)
         .padding(.bottom, bottomPadding)
         .frame(maxWidth: .infinity)
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
