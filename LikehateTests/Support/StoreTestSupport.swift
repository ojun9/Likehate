import Foundation
import Testing
import UIKit
@testable import Likehate

@MainActor
struct StoreTestContext {
   let suiteName: String
   let defaults: UserDefaults
   let store: LikeHateStore

   init(initialValues: ((UserDefaults) -> Void)? = nil, premiumPurchaseService: PremiumPurchaseServicing? = nil) throws {
      suiteName = "LikehateTests-\(UUID().uuidString)"
      guard let defaults = UserDefaults(suiteName: suiteName) else {
         throw StoreTestError.userDefaultsUnavailable
      }
      defaults.removePersistentDomain(forName: suiteName)
      initialValues?(defaults)

      self.defaults = defaults
      if let premiumPurchaseService {
         store = LikeHateStore(defaults: defaults, premiumPurchaseService: premiumPurchaseService)
      } else {
         store = LikeHateStore(defaults: defaults)
      }
   }

   func cleanup() {
      defaults.removePersistentDomain(forName: suiteName)
   }
}

@MainActor
final class PremiumPurchaseServiceStub: PremiumPurchaseServicing {
   var currentEntitlementStateResult: Result<PremiumEntitlementState, Error> = .success(.inactive)
   var currentPremiumPackageResult: Result<PremiumPackage?, Error> = .success(nil)
   var purchaseResult: Result<PremiumPurchaseResult, Error> = .success(.inactive)
   var restoreResult: Result<PremiumPurchaseResult, Error> = .success(.inactive)

   private(set) var didRequestCurrentEntitlementState = false
   private(set) var didRequestCurrentPremiumPackage = false
   private(set) var didPurchase = false
   private(set) var didRestore = false

   func currentEntitlementState() async throws -> PremiumEntitlementState {
      didRequestCurrentEntitlementState = true
      return try currentEntitlementStateResult.get()
   }

   func currentPremiumPackage() async throws -> PremiumPackage? {
      didRequestCurrentPremiumPackage = true
      return try currentPremiumPackageResult.get()
   }

   func purchase(package: PremiumPackage) async throws -> PremiumPurchaseResult {
      didPurchase = true
      return try purchaseResult.get()
   }

   func restorePurchases() async throws -> PremiumPurchaseResult {
      didRestore = true
      return try restoreResult.get()
   }
}

@MainActor
func waitUntil(_ predicate: @escaping @MainActor () -> Bool) async throws {
   for _ in 0..<100 {
      if predicate() {
         return
      }
      try await Task.sleep(nanoseconds: 1_000_000)
   }
   Issue.record("Timed out waiting for async store work")
}

enum StoreTestError: Error {
   case userDefaultsUnavailable
}

enum TestImageError: Error {
   case missingJPEGData
}

@MainActor
enum TestImageFactory {
   static func jpegData(size: CGSize, color: UIColor) throws -> Data {
      let renderer = UIGraphicsImageRenderer(size: size)
      let image = renderer.image { context in
         color.setFill()
         context.fill(CGRect(origin: .zero, size: size))
      }

      guard let data = image.jpegData(compressionQuality: 0.9) else {
         throw TestImageError.missingJPEGData
      }
      return data
   }
}

func makeStoredPerson(
   id: UUID = UUID(),
   name: String,
   profileImageName: String?,
   isMe: Bool,
   createdAt: Date = Date(),
   sortOrder: Int
) -> Person {
   Person(
      id: id,
      name: name,
      profileImageName: profileImageName,
      photoFileName: nil,
      isMe: isMe,
      createdAt: createdAt,
      updatedAt: createdAt,
      sortOrder: sortOrder
   )
}

func makeStoredItem(
   personID: UUID,
   kind: EntryKind,
   title: String,
   sortOrder: Int,
   createdAt: Date = Date()
) -> LikeDislikeItem {
   LikeDislikeItem(
      id: UUID(),
      personId: personID,
      type: kind,
      title: title,
      note: nil,
      createdAt: createdAt,
      updatedAt: createdAt,
      sortOrder: sortOrder
   )
}

func storeEncoded<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults) throws {
   defaults.set(try JSONEncoder().encode(value), forKey: key)
}
