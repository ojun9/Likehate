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
   fileprivate let revenueCatStoreProduct: StoreProduct?

   init(localizedPrice: String) {
      self.localizedPrice = localizedPrice
      self.revenueCatStoreProduct = nil
   }

   fileprivate init(localizedPrice: String, revenueCatStoreProduct: StoreProduct) {
      self.localizedPrice = localizedPrice
      self.revenueCatStoreProduct = revenueCatStoreProduct
   }
}

enum PremiumPurchaseServiceError: Error {
   case missingRevenueCatProduct
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
      let products = await Purchases.shared.products([LikehateRevenueCatContracts.premiumProductID])
      guard let product = products.first(where: { $0.productIdentifier == LikehateRevenueCatContracts.premiumProductID }) else {
         return nil
      }
      return PremiumPackage(localizedPrice: product.localizedPriceString, revenueCatStoreProduct: product)
   }

   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult {
      guard let revenueCatStoreProduct = package.revenueCatStoreProduct else {
         throw PremiumPurchaseServiceError.missingRevenueCatProduct
      }

      do {
         let result = try await Purchases.shared.purchase(product: revenueCatStoreProduct)
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
