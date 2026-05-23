import FirebaseAnalytics
import Foundation
import SwiftyStoreKit

@MainActor
final class LikeHateStore: ObservableObject {
   private enum Constants {
      static let noAdsProductID = "NO_ADS_LIKEHATE"
      static let receiptSharedSecret = "50822b94b56840bb845871be8d3352ab"
      static let launchReviewRequestCountKey = "LaunchReviewRequestCount"
      static let registrationReviewRequestCountKey = "RegistrationReviewRequestCount"
   }

   @Published private(set) var likes: [String]
   @Published private(set) var hates: [String]
   @Published var didBuyRemoveAd: Bool
   @Published var purchaseMessage: PurchaseMessage?
   @Published var reviewPrompt: ReviewPrompt?
   @Published var isPurchasing = false
   @Published var isRestoring = false

   private let defaults: UserDefaults

   init(defaults: UserDefaults = .standard) {
      self.defaults = defaults
      self.likes = defaults.stringArray(forKey: EntryKind.like.storageKey) ?? []
      self.hates = defaults.stringArray(forKey: EntryKind.hate.storageKey) ?? []
      self.didBuyRemoveAd = defaults.bool(forKey: "BuyRemoveAd")
   }

   func items(for kind: EntryKind) -> [String] {
      switch kind {
      case .like: return likes
      case .hate: return hates
      }
   }

   func add(_ text: String, to kind: EntryKind) {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return }

      switch kind {
      case .like:
         likes.append(trimmed)
         defaults.set(likes, forKey: kind.storageKey)
      case .hate:
         hates.append(trimmed)
         defaults.set(hates, forKey: kind.storageKey)
      }

      Analytics.logEvent(kind.analyticsName, parameters: analyticsParameters(for: kind, textLength: trimmed.count))
      Analytics.logEvent("entry_saved", parameters: analyticsParameters(for: kind, textLength: trimmed.count))
      HapticsClient.success()
      recordRegistrationAndRequestReviewIfNeeded()
   }

   func recordLaunchAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.launchReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.launchReviewRequestCountKey)

      Analytics.logEvent("app_launch_count_recorded", parameters: [
         "launch_count": nextCount,
         "like_count": likes.count,
         "hate_count": hates.count,
         "did_buy_remove_ad": didBuyRemoveAd
      ])
      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByLaunchCount")
   }

   func delete(at offsets: IndexSet, from kind: EntryKind) {
      let deletedCount = offsets.count
      switch kind {
      case .like:
         likes.remove(atOffsets: offsets)
         defaults.set(likes, forKey: kind.storageKey)
      case .hate:
         hates.remove(atOffsets: offsets)
         defaults.set(hates, forKey: kind.storageKey)
      }

      Analytics.logEvent("entry_deleted", parameters: analyticsParameters(for: kind).merging([
         "deleted_count": deletedCount
      ]) { _, new in new })
   }

   func move(from source: IndexSet, to destination: Int, in kind: EntryKind) {
      switch kind {
      case .like:
         likes.move(fromOffsets: source, toOffset: destination)
         defaults.set(likes, forKey: kind.storageKey)
      case .hate:
         hates.move(fromOffsets: source, toOffset: destination)
         defaults.set(hates, forKey: kind.storageKey)
      }

      Analytics.logEvent("entry_reordered", parameters: analyticsParameters(for: kind).merging([
         "moved_count": source.count,
         "destination": destination
      ]) { _, new in new })
   }

   func deleteAll() {
      let likeCount = likes.count
      let hateCount = hates.count
      likes.removeAll()
      hates.removeAll()
      defaults.removeObject(forKey: EntryKind.like.storageKey)
      defaults.removeObject(forKey: EntryKind.hate.storageKey)
      Analytics.logEvent("delete all date", parameters: nil)
      Analytics.logEvent("all_entries_deleted", parameters: [
         "like_count": likeCount,
         "hate_count": hateCount,
         "total_count": likeCount + hateCount
      ])
   }

   func purchaseNoAds() {
      guard !isPurchasing else { return }
      isPurchasing = true
      Analytics.logEvent("TapNoAdsInClearView", parameters: nil)
      Analytics.logEvent("purchase_no_ads_started", parameters: [
         "did_buy_remove_ad": didBuyRemoveAd
      ])

      SwiftyStoreKit.purchaseProduct(Constants.noAdsProductID, quantity: 1, atomically: true) { [weak self] result in
         Task { @MainActor in
            guard let self else { return }
            self.isPurchasing = false

            switch result {
            case .success(let purchase):
               if purchase.needsFinishTransaction {
                  SwiftyStoreKit.finishTransaction(purchase.transaction)
               }
               self.setAdRemoved(true)
               self.verifyNoAdsPurchase()
               self.purchaseMessage = PurchaseMessage(title: String(localized: "Passed."), message: "Purchase complete")
               Analytics.logEvent("purchase_no_ads_succeeded", parameters: nil)
            case .error(let error):
               self.purchaseMessage = PurchaseMessage(title: "Purchase failed", message: error.localizedDescription)
               Analytics.logEvent("purchase_no_ads_failed", parameters: [
                  "error_code": error.code.rawValue
               ])
            case .deferred:
               self.purchaseMessage = PurchaseMessage(title: "Purchase deferred", message: "The purchase is pending approval.")
               Analytics.logEvent("purchase_no_ads_deferred", parameters: nil)
            }
         }
      }
   }

   func restorePurchases() {
      guard !isRestoring else { return }
      isRestoring = true
      Analytics.logEvent("restore_purchases_started", parameters: [
         "did_buy_remove_ad": didBuyRemoveAd
      ])

      SwiftyStoreKit.restorePurchases(atomically: true) { [weak self] results in
         Task { @MainActor in
            guard let self else { return }
            self.isRestoring = false

            if let error = results.restoreFailedPurchases.first?.0 {
               let nsError = error as NSError
               self.purchaseMessage = PurchaseMessage(title: "Restore failed", message: error.localizedDescription)
               Analytics.logEvent("restore_purchases_failed", parameters: [
                  "failed_count": results.restoreFailedPurchases.count,
                  "restored_count": results.restoredPurchases.count,
                  "error_domain": nsError.domain,
                  "error_code": nsError.code
               ])
            } else if results.restoredPurchases.contains(where: { $0.productId == Constants.noAdsProductID }) {
               self.setAdRemoved(true)
               self.purchaseMessage = PurchaseMessage(title: String(localized: "Passed."), message: "Restore successful")
               Analytics.logEvent("restore_purchases_succeeded", parameters: [
                  "restored_count": results.restoredPurchases.count
               ])
            } else {
               self.purchaseMessage = PurchaseMessage(title: "Restore", message: "No purchases were found.")
               Analytics.logEvent("restore_purchases_empty", parameters: [
                  "restored_count": results.restoredPurchases.count
               ])
            }
         }
      }
   }

   private func setAdRemoved(_ value: Bool) {
      didBuyRemoveAd = value
      defaults.set(value, forKey: "BuyRemoveAd")
      NotificationCenter.default.post(name: .didRemoveAds, object: nil)
   }

   private func verifyNoAdsPurchase() {
      let validator = AppleReceiptValidator(service: .production, sharedSecret: Constants.receiptSharedSecret)
      SwiftyStoreKit.verifyReceipt(using: validator) { result in
         switch result {
         case .success(let receipt):
            let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: Constants.noAdsProductID, inReceipt: receipt)
            print("購入の検証: \(purchaseResult)")
         case .error(let error):
            print("verifyPurchaseエラー: \(error)")
         }
      }
   }

   private func recordRegistrationAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.registrationReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.registrationReviewRequestCountKey)

      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByRegistrationCount")
   }

   private func requestReviewIfNeeded(count: Int, eventName: String) {
      guard count == 10 || count == 20 else { return }

      Analytics.logEvent(eventName, parameters: ["count": count])
      Analytics.logEvent("review_prompt_requested", parameters: [
         "trigger": eventName,
         "count": count,
         "like_count": likes.count,
         "hate_count": hates.count
      ])
      AppReviewClient.requestReview()
   }

   private func analyticsParameters(for kind: EntryKind, textLength: Int? = nil) -> [String: Any] {
      var parameters: [String: Any] = [
         "kind": kind.rawValue,
         "kind_count": items(for: kind).count,
         "like_count": likes.count,
         "hate_count": hates.count,
         "total_count": likes.count + hates.count
      ]

      if let textLength {
         parameters["text_length"] = textLength
      }

      return parameters
   }
}
