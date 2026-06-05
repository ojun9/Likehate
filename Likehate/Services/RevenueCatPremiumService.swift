import Foundation
import RevenueCat

enum LikehateRevenueCatContracts {
   static let publicSDKKey = "appl_KjaunKCKXyQMEbmdzqjXhbbiEkG"
   static let premiumProductID = "NO_ADS_LIKEHATE"
   static let premiumEntitlementID = "premium"
}

enum PremiumEntitlementState: Equatable {
   case active
   case inactive
   case missingCustomerInfo
   case missingEntitlement

   var isActive: Bool {
      if case .active = self {
         return true
      }
      return false
   }
}

enum PremiumPurchaseResult: Equatable {
   case active
   case inactive
   case userCancelled
   case missingCustomerInfo
   case missingEntitlement
   case missingPackage
}

struct PremiumPackage {
   let localizedPrice: String
   fileprivate let revenueCatPackage: Package?

   init(localizedPrice: String) {
      self.localizedPrice = localizedPrice
      self.revenueCatPackage = nil
   }

   fileprivate init(localizedPrice: String, revenueCatPackage: Package) {
      self.localizedPrice = localizedPrice
      self.revenueCatPackage = revenueCatPackage
   }
}

enum PremiumPurchaseServiceError: Error {
   case missingRevenueCatPackage
}

enum RevenueCatPurchaseErrorClassifier {
   static func isPurchaseCancelled(_ error: Error) -> Bool {
      let nsError = error as NSError
      let purchaseCancelledError = ErrorCode.purchaseCancelledError as NSError
      return nsError.domain == purchaseCancelledError.domain && nsError.code == purchaseCancelledError.code
   }
}

@MainActor
protocol PremiumPurchaseServicing {
   func currentEntitlementState() async throws -> PremiumEntitlementState
   func currentPremiumPackage() async throws -> PremiumPackage?
   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult
   func restorePurchases() async throws -> PremiumPurchaseResult
}

@MainActor
final class RevenueCatPremiumPurchaseService: PremiumPurchaseServicing {
   func currentEntitlementState() async throws -> PremiumEntitlementState {
      let customerInfo = try await Purchases.shared.customerInfo()
      return Self.entitlementState(from: customerInfo)
   }

   func currentPremiumPackage() async throws -> PremiumPackage? {
      let offerings = try await Purchases.shared.offerings()
      guard let offering = offerings.current else { return nil }
      let availablePackages = offering.availablePackages
      guard let package = availablePackages.first(where: { $0.storeProduct.productIdentifier == LikehateRevenueCatContracts.premiumProductID }) ?? availablePackages.first else {
         return nil
      }
      return PremiumPackage(localizedPrice: package.storeProduct.localizedPriceString, revenueCatPackage: package)
   }

   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult {
      guard let revenueCatPackage = package.revenueCatPackage else {
         throw PremiumPurchaseServiceError.missingRevenueCatPackage
      }

      do {
         let result = try await Purchases.shared.purchase(package: revenueCatPackage)
         if result.userCancelled {
            return .userCancelled
         }
         return Self.purchaseResult(from: result.customerInfo)
      } catch {
         if RevenueCatPurchaseErrorClassifier.isPurchaseCancelled(error) {
            return .userCancelled
         }
         throw error
      }
   }

   func restorePurchases() async throws -> PremiumPurchaseResult {
      let customerInfo = try await Purchases.shared.restorePurchases()
      return Self.purchaseResult(from: customerInfo)
   }

   nonisolated static func entitlementState(from customerInfo: CustomerInfo?) -> PremiumEntitlementState {
      guard let customerInfo else {
         return .missingCustomerInfo
      }

      guard let entitlement = customerInfo.entitlements[LikehateRevenueCatContracts.premiumEntitlementID] else {
         return .missingEntitlement
      }

      return entitlement.isActive ? .active : .inactive
   }

   nonisolated private static func purchaseResult(from customerInfo: CustomerInfo?) -> PremiumPurchaseResult {
      switch entitlementState(from: customerInfo) {
      case .active:
         return .active
      case .inactive:
         return .inactive
      case .missingCustomerInfo:
         return .missingCustomerInfo
      case .missingEntitlement:
         return .missingEntitlement
      }
   }
}

extension CustomerInfo {
   var likehatePremiumEntitlementIsActive: Bool? {
      entitlements[LikehateRevenueCatContracts.premiumEntitlementID]?.isActive
   }
}
