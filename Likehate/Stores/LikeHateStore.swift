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

      Analytics.logEvent(kind.analyticsName, parameters: nil)
      HapticsClient.success()
      recordRegistrationAndRequestReviewIfNeeded()
   }

   func recordLaunchAndRequestReviewIfNeeded() {
      let nextCount = defaults.integer(forKey: Constants.launchReviewRequestCountKey) + 1
      defaults.set(nextCount, forKey: Constants.launchReviewRequestCountKey)

      requestReviewIfNeeded(count: nextCount, eventName: "requestReviewByLaunchCount")
   }

   func delete(at offsets: IndexSet, from kind: EntryKind) {
      switch kind {
      case .like:
         likes.remove(atOffsets: offsets)
         defaults.set(likes, forKey: kind.storageKey)
      case .hate:
         hates.remove(atOffsets: offsets)
         defaults.set(hates, forKey: kind.storageKey)
      }
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
   }

   func deleteAll() {
      likes = []
      hates = []
      defaults.set(likes, forKey: EntryKind.like.storageKey)
      defaults.set(hates, forKey: EntryKind.hate.storageKey)
      Analytics.logEvent("delete all date", parameters: nil)
   }

   func purchaseNoAds() {
      guard !isPurchasing else { return }
      isPurchasing = true
      Analytics.logEvent("TapNoAdsInClearView", parameters: nil)

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
            case .error(let error):
               self.purchaseMessage = PurchaseMessage(title: "Purchase failed", message: error.localizedDescription)
            case .deferred:
               self.purchaseMessage = PurchaseMessage(title: "Purchase deferred", message: "The purchase is pending approval.")
            }
         }
      }
   }

   func restorePurchases() {
      guard !isRestoring else { return }
      isRestoring = true

      SwiftyStoreKit.restorePurchases(atomically: true) { [weak self] results in
         Task { @MainActor in
            guard let self else { return }
            self.isRestoring = false

            if let error = results.restoreFailedPurchases.first?.0 {
               self.purchaseMessage = PurchaseMessage(title: "Restore failed", message: error.localizedDescription)
            } else if results.restoredPurchases.contains(where: { $0.productId == Constants.noAdsProductID }) {
               self.setAdRemoved(true)
               self.purchaseMessage = PurchaseMessage(title: String(localized: "Passed."), message: "Restore successful")
            } else {
               self.purchaseMessage = PurchaseMessage(title: "Restore", message: "No purchases were found.")
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
      AppReviewClient.requestReview()
   }
}
