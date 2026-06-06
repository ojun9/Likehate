import Foundation
import RevenueCat

/// RevenueCatとApp Store Connectで共有する課金契約値。
enum LikehateRevenueCatContracts {
   static let publicSDKKey = "appl_KjaunKCKXyQMEbmdzqjXhbbiEkG"
   static let premiumProductID = "NO_ADS_LIKEHATE"
   static let premiumEntitlementID = "premium"
}

/// RevenueCatから読み取ったプレミアム権利の状態。
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

/// RevenueCatの購入・復元処理の結果。
enum PremiumPurchaseResult: Equatable {
   case active
   case inactive
   case userCancelled
   case missingCustomerInfo
   case missingEntitlement
   case missingPackage
}

/// プレミアム購入画面で扱う購入商品情報。
struct PremiumPackage {
   /// RevenueCatから取得した表示用価格。
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

/// プレミアム購入サービス内で発生する独自エラー。
enum PremiumPurchaseServiceError: Error {
   case missingRevenueCatProduct
}

/// RevenueCatのエラーを購入キャンセルとして扱えるか判定する分類器。
enum RevenueCatPurchaseErrorClassifier {
   static func isPurchaseCancelled(_ error: Error) -> Bool {
      let nsError = error as NSError
      let purchaseCancelledError = ErrorCode.purchaseCancelledError as NSError
      return nsError.domain == purchaseCancelledError.domain && nsError.code == purchaseCancelledError.code
   }
}

/// プレミアム購入・復元処理を抽象化するプロトコル。
@MainActor
protocol PremiumPurchaseServicing {
   /// 現在有効なプレミアム権利状態を取得する。
   func currentEntitlementState() async throws -> PremiumEntitlementState
   /// 現在購入可能なプレミアム商品を取得する。
   func currentPremiumPackage() async throws -> PremiumPackage?
   /// 指定された商品を購入する。
   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult
   /// 購入履歴を復元する。
   func restorePurchases() async throws -> PremiumPurchaseResult
}

/// RevenueCat SDKを使う本番用のプレミアム購入サービス。
@MainActor
final class RevenueCatPremiumPurchaseService: PremiumPurchaseServicing {
   /// RevenueCatのCustomerInfoから現在の権利状態を取得する。
   func currentEntitlementState() async throws -> PremiumEntitlementState {
      let customerInfo = try await Purchases.shared.customerInfo()
      return Self.entitlementState(from: customerInfo)
   }

   /// App Store product IDから買い切りプレミアム商品を取得する。
   func currentPremiumPackage() async throws -> PremiumPackage? {
      let products = await Purchases.shared.products([LikehateRevenueCatContracts.premiumProductID])
      guard let product = products.first(where: { $0.productIdentifier == LikehateRevenueCatContracts.premiumProductID }) else {
         return nil
      }
      return PremiumPackage(localizedPrice: product.localizedPriceString, revenueCatStoreProduct: product)
   }

   /// RevenueCat経由で買い切りプレミアムを購入する。
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

   /// RevenueCat経由で購入履歴を復元する。
   func restorePurchases() async throws -> PremiumPurchaseResult {
      let customerInfo = try await Purchases.shared.restorePurchases()
      return Self.purchaseResult(from: customerInfo)
   }

   /// CustomerInfoからプレミアム権利状態を解釈する。
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
   /// LikehateのプレミアムEntitlementが有効かどうか。
   var likehatePremiumEntitlementIsActive: Bool? {
      entitlements[LikehateRevenueCatContracts.premiumEntitlementID]?.isActive
   }
}
