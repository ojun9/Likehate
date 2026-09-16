import Foundation
import Testing
@testable import Likehate

@MainActor
struct LikeHateStoreOnboardingDefaultsTests {
   @Test("新規インストールではオンボーディングを自動表示する")
   func freshInstallPresentsOnboarding() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      #expect(context.store.showsOnboarding)
      #expect(context.store.shouldPresentOnboarding)
      #expect(context.defaults.object(forKey: "OnboardingEnabled") as? Bool == true)
   }

   @Test("起動履歴のある既存ユーザーにはオンボーディングを自動表示しない")
   func existingInstallDoesNotPresentOnboarding() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(1, forKey: "LaunchReviewRequestCount")
      })
      defer { context.cleanup() }

      #expect(context.store.showsOnboarding == false)
      #expect(context.store.shouldPresentOnboarding == false)
      #expect(context.defaults.object(forKey: "OnboardingEnabled") as? Bool == false)
   }

   @Test("明示的に無効化したオンボーディング設定を維持する")
   func explicitDisabledPreferenceWins() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(false, forKey: "OnboardingEnabled")
      })
      defer { context.cleanup() }

      #expect(context.store.showsOnboarding == false)
      #expect(context.store.shouldPresentOnboarding == false)
   }

   @Test("既存ユーザーの明示的な有効設定を維持する")
   func explicitEnabledPreferenceWins() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(1, forKey: "LaunchReviewRequestCount")
         defaults.set(true, forKey: "OnboardingEnabled")
      })
      defer { context.cleanup() }

      #expect(context.store.showsOnboarding)
      #expect(context.store.shouldPresentOnboarding)
   }
}
