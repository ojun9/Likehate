import GoogleMobileAds
import SwiftUI
import UIKit

/// 一覧系画面で使うAdMob広告ユニットID。
private enum AdMobUnitID: Sendable {
    #if DEBUG
   static let itemListBanner = "ca-app-pub-3940256099942544/2435281174"
    #else
   static let itemListBanner = "ca-app-pub-1460017825820383/1086930169"
    #endif
}

/// 広告表示場所を分析イベントで区別するための識別子。
enum ListAdPlacement: String, Sendable {
   case itemList = "item_list"
   case comparisonCategoryDetail = "comparison_category_detail"
}

final class AdBannerContainerView: UIView {
   let bannerView: BannerView

   init(adSize: AdSize) {
      self.bannerView = BannerView(adSize: adSize)
      super.init(frame: .zero)

      clipsToBounds = true
      bannerView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(bannerView)
      NSLayoutConstraint.activate([
         bannerView.centerXAnchor.constraint(equalTo: centerXAnchor),
         bannerView.centerYAnchor.constraint(equalTo: centerYAnchor)
      ])
   }

   @available(*, unavailable)
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   override var intrinsicContentSize: CGSize {
      .zero
   }
}

private struct AdBannerRotationObserver: UIViewControllerRepresentable {
   let onTransition: @MainActor () -> Void

   func makeUIViewController(context: Context) -> Controller {
      let controller = Controller()
      controller.onTransition = onTransition
      return controller
   }

   func updateUIViewController(_ uiViewController: Controller, context: Context) {
      uiViewController.onTransition = onTransition
   }

   final class Controller: UIViewController {
      var onTransition: (@MainActor () -> Void)?

      override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
         super.viewWillTransition(to: size, with: coordinator)

         coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.onTransition?()
         }
      }
   }
}

/// Google Mobile AdsのバナーViewをSwiftUIで扱うためのラッパー。
struct LikehateAdBannerView: UIViewRepresentable {
   let adSize: AdSize
   let adUnitID: String
   let layoutID: Int
   let placement: ListAdPlacement
   let onHeightChange: @MainActor (CGFloat) -> Void

   init(
      adUnitID: String,
      adSize: AdSize,
      layoutID: Int,
      placement: ListAdPlacement,
      onHeightChange: @escaping @MainActor (CGFloat) -> Void
   ) {
      self.adUnitID = adUnitID
      self.adSize = adSize
      self.layoutID = layoutID
      self.placement = placement
      self.onHeightChange = onHeightChange
   }

   func makeUIView(context: Context) -> AdBannerContainerView {
      let container = AdBannerContainerView(adSize: adSize)
      let banner = container.bannerView
      banner.adUnitID = adUnitID
      banner.delegate = context.coordinator
      banner.rootViewController = UIApplication.shared.likehateRootViewController
      banner.clipsToBounds = true
      context.coordinator.loadedLayoutID = layoutID
      banner.load(Request())
      return container
   }

   func updateUIView(_ uiView: AdBannerContainerView, context: Context) {
      let banner = uiView.bannerView
      context.coordinator.onHeightChange = onHeightChange
      let didChangeAdSize = !isAdSizeEqualToSize(size1: banner.adSize, size2: adSize)
      let didChangeLayout = context.coordinator.loadedLayoutID != layoutID

      if didChangeAdSize {
         banner.adSize = adSize
      }
      banner.rootViewController = UIApplication.shared.likehateRootViewController
      banner.delegate = context.coordinator
      banner.clipsToBounds = true
      uiView.clipsToBounds = true

      if didChangeAdSize || didChangeLayout {
         context.coordinator.loadedLayoutID = layoutID
         banner.load(Request())
      }
   }

   func makeCoordinator() -> Coordinator {
      Coordinator(adUnitID: adUnitID, placement: placement, onHeightChange: onHeightChange)
   }

   /// AdMobバナーの読み込み結果を分析イベントへ変換するデリゲート。
   final class Coordinator: NSObject, BannerViewDelegate {
      init(
         adUnitID: String,
         placement: ListAdPlacement,
         onHeightChange: @escaping @MainActor (CGFloat) -> Void
      ) {
         self.adUnitID = adUnitID
         self.placement = placement
         self.onHeightChange = onHeightChange
      }

      private let adUnitID: String
      private let placement: ListAdPlacement
      var onHeightChange: @MainActor (CGFloat) -> Void
      var loadedLayoutID: Int?

      func bannerViewDidReceiveAd(_ bannerView: BannerView) {
         print("AdMob banner loaded: \(adUnitID)")
         reportHeight(bannerView.intrinsicContentSize.height)
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

      @MainActor
      private func reportHeight(_ height: CGFloat) {
         guard height > 0 else { return }
         onHeightChange(height)
      }
   }
}

/// 画面幅に合わせたインライン適応バナーを表示するView。
struct LikehateAdaptiveAdBanner: View {
   private static let placeholderHeight: CGFloat = 50

   private struct BannerLayoutKey: Equatable {
      let adWidth: CGFloat
      let interfaceOrientation: UIInterfaceOrientation
      let windowSize: CGSize
   }

   let adUnitID: String
   let placement: ListAdPlacement
   @State private var adWidth: CGFloat = 0
   @State private var bannerHeight: CGFloat = 0
   @State private var contentWidth: CGFloat = 0
   @State private var layoutID = 0
   @State private var layoutKey: BannerLayoutKey?

   var body: some View {
      let contentHeight = bannerHeight > 0 ? bannerHeight : Self.placeholderHeight

      Color.clear
         .frame(maxWidth: .infinity)
         .frame(height: contentHeight)
         .overlay {
            if adWidth > 0 {
               let adSize = currentOrientationInlineAdaptiveBanner(width: adWidth)

               LikehateAdBannerView(
                  adUnitID: adUnitID,
                  adSize: adSize,
                  layoutID: layoutID,
                  placement: placement
               ) { height in
                  bannerHeight = height
               }
               .frame(width: adWidth, height: contentHeight)
               .clipped()
               .onAppear {
                  FAAnalytics.log(.track(.adBannerContainerAppeared, parameters: [
                     .placement: placement.rawValue,
                     .availableWidth: adWidth
                  ]))
               }
            }
         }
         .background {
            GeometryReader { proxy in
               Color.clear
                  .preference(key: BannerWidthPreferenceKey.self, value: proxy.size.width)
            }
         }
         .onPreferenceChange(BannerWidthPreferenceKey.self) { width in
            contentWidth = floor(width)
            updateBannerLayout(fallbackWidth: contentWidth)
         }
         .background {
            AdBannerRotationObserver {
               updateBannerLayout(fallbackWidth: contentWidth)
            }
         }
         .frame(height: contentHeight + 8)
         .background(Color.clear)
   }

   @MainActor
   private func updateBannerLayout(fallbackWidth: CGFloat) {
      guard let nextLayoutKey = Self.bannerLayoutKey(fallbackWidth: fallbackWidth),
            nextLayoutKey != layoutKey else { return }

      layoutKey = nextLayoutKey
      adWidth = nextLayoutKey.adWidth
      bannerHeight = 0
      layoutID += 1
   }

   @MainActor
   private static func bannerLayoutKey(fallbackWidth: CGFloat) -> BannerLayoutKey? {
      if let scene = UIApplication.shared.likehateWindowScene,
         let window = scene.keyWindow ?? scene.windows.first(where: \.isKeyWindow) {
         let safeAreaWidth = window.bounds.inset(by: window.safeAreaInsets).width
         if safeAreaWidth > 0 {
            return BannerLayoutKey(
               adWidth: floor(safeAreaWidth),
               interfaceOrientation: scene.effectiveGeometry.interfaceOrientation,
               windowSize: CGSize(width: floor(window.bounds.width), height: floor(window.bounds.height))
            )
         }
      }

      let fallbackAdWidth = floor(fallbackWidth)
      guard fallbackAdWidth > 0 else { return nil }
      return BannerLayoutKey(
         adWidth: fallbackAdWidth,
         interfaceOrientation: .unknown,
         windowSize: .zero
      )
   }
}

/// 一覧系画面で、広告表示条件を満たす場合だけバナーを差し込むView。
struct ConditionalListAdBanner: View {
   @EnvironmentObject private var store: LikeHateStore

   let placement: ListAdPlacement
   let hasItems: Bool
   var topPadding: CGFloat = 16
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
