import Foundation
import Testing
@testable import Likehate

@MainActor
struct LikeHateStoreSettingsTests {
   @Test("デフォルト設定は控えめで読みやすい")
   func defaultSettings() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let settings = context.store.appSettings

      #expect(settings.animationEnabled)
      #expect(settings.vibrationEnabled)
      #expect(settings.adsRemoved == false)
      #expect(settings.isPremium == false)
      #expect(settings.textSize == .standard)
      #expect(settings.showsOnboarding == false)
      #expect(context.store.showsOnboarding == false)
      #expect(context.store.shouldPresentOnboarding == false)
   }

   @Test("不正な保存文字サイズは標準に戻る")
   func invalidStoredTextSizeFallsBackToStandard() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set("giant", forKey: "AppTextSize")
      })
      defer { context.cleanup() }

      #expect(context.store.textSize == .standard)
   }

   @Test("文字サイズはユーザーデフォルトとアプリ設定に永続化される")
   func textSizePersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.textSize = .extraLarge

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.textSize == .extraLarge)
      #expect(reloadedStore.appSettings.textSize == .extraLarge)
   }

   @Test("アニメーション設定はユーザーデフォルトに永続化される")
   func animationSettingPersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.animationEnabled = false

      let reloadedStore = LikeHateStore(defaults: context.defaults)

      #expect(reloadedStore.animationEnabled == false)
      #expect(reloadedStore.appSettings.animationEnabled == false)
   }

   @Test("オンボーディング表示フラグは初期値falseで永続化される")
   func onboardingPresentationFlagPersists() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      store.showsOnboarding = true

      let reloadedStore = LikeHateStore(defaults: context.defaults)

      #expect(reloadedStore.showsOnboarding)
      #expect(reloadedStore.appSettings.showsOnboarding)
      #expect(reloadedStore.shouldPresentOnboarding)
   }

   @Test("オンボーディング完了後は表示フラグがtrueでも自動表示しない")
   func completedOnboardingStopsAutomaticPresentation() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(true, forKey: "OnboardingEnabled")
      })
      defer { context.cleanup() }

      let store = context.store
      #expect(store.shouldPresentOnboarding)

      store.completeOnboarding()

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      #expect(reloadedStore.showsOnboarding)
      #expect(reloadedStore.hasCompletedOnboarding)
      #expect(reloadedStore.shouldPresentOnboarding == false)
   }

   @Test("アプリ設定は永続化された触覚と広告フラグを読む")
   func appSettingsReadPersistedHapticsAndAdFlags() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(false, forKey: "HapticsEnabled")
         defaults.set(true, forKey: "BuyRemoveAd")
      })
      defer { context.cleanup() }

      let settings = context.store.appSettings

      #expect(settings.vibrationEnabled == false)
      #expect(settings.adsRemoved)
      #expect(settings.isPremium)
   }

   #if DEBUG
   @Test("アップストアスクショモードはサンプルデータへ差し替え元データを復元する")
   func appStoreScreenshotModeSwapsAndRestoresOriginalData() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      let friend = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage8))
      store.add("焼き魚", to: .like, personID: friend.id)
      store.add("梅干し", to: .hate, personID: me.id)

      let originalPersonIDs = store.persons.map(\.id)
      let originalEntryTitles = store.entries.map(\.title)

      store.setAppStoreScreenshotModeEnabled(true)

      let sampleMe = try #require(store.mePerson)
      let expectedSampleData = LikeHateStore.makeAppStoreScreenshotData(
         now: Date(),
         locale: Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
      )
      let expectedPersons = expectedSampleData.persons
      let sampleAkari = try #require(store.persons.first { $0.id == expectedPersons[1].id })
      let sampleHaruto = try #require(store.persons.first { $0.id == expectedPersons[2].id })
      #expect(store.isAppStoreScreenshotModeEnabled)
      #expect(store.persons.map(\.displayName) == expectedPersons.map(\.displayName))
      #expect(sampleHaruto.profileImageName == DefaultProfileImage.defaultProfileImage16.rawValue)
      let sampleCounts = [
         store.items(for: sampleMe.id, kind: .like).count,
         store.items(for: sampleMe.id, kind: .hate).count,
         store.items(for: sampleAkari.id, kind: .like).count,
         store.items(for: sampleAkari.id, kind: .hate).count,
         store.items(for: sampleHaruto.id, kind: .like).count,
         store.items(for: sampleHaruto.id, kind: .hate).count
      ]
      #expect(sampleCounts == [23, 16, 29, 14, 21, 27])
      #expect(sampleCounts.allSatisfy { (14...30).contains($0) })
      #expect(sampleCounts.min() == 14)
      #expect(sampleCounts.max() == 29)
      #expect(Set(sampleCounts).count == sampleCounts.count)
      #expect(store.entries.count == sampleCounts.reduce(0, +))
      #expect(store.person(for: friend.id) == nil)

      let meAndAkariSections = Dictionary(uniqueKeysWithValues: store
         .comparisonSections(firstPersonID: sampleMe.id, secondPersonID: sampleAkari.id)
         .map { ($0.category, $0.titles) })
      let expectedMeLikes = expectedSampleData.entries
         .filter { $0.personId == expectedPersons[0].id && $0.type == .like }
         .map(\.title)
      let expectedMeHates = expectedSampleData.entries
         .filter { $0.personId == expectedPersons[0].id && $0.type == .hate }
         .map(\.title)
      let expectedAkariLikes = expectedSampleData.entries
         .filter { $0.personId == expectedPersons[1].id && $0.type == .like }
         .map(\.title)
      let expectedAkariHates = expectedSampleData.entries
         .filter { $0.personId == expectedPersons[1].id && $0.type == .hate }
         .map(\.title)
      let expectedCommonLike = try #require(expectedMeLikes.first { expectedAkariLikes.contains($0) })
      let expectedCommonHate = try #require(expectedMeHates.first { expectedAkariHates.contains($0) })
      let expectedFirstOnlyLike = try #require(expectedMeLikes.first { expectedAkariLikes.contains($0) == false })
      let expectedSecondOnlyLike = try #require(expectedAkariLikes.first { expectedMeLikes.contains($0) == false })
      #expect(meAndAkariSections[.commonLike]?.contains(expectedCommonLike) == true)
      #expect(meAndAkariSections[.commonHate]?.contains(expectedCommonHate) == true)
      #expect(meAndAkariSections[.firstOnlyLike]?.contains(expectedFirstOnlyLike) == true)
      #expect(meAndAkariSections[.secondOnlyLike]?.contains(expectedSecondOnlyLike) == true)

      store.setAppStoreScreenshotModeEnabled(false)

      #expect(store.isAppStoreScreenshotModeEnabled == false)
      #expect(store.persons.map(\.id) == originalPersonIDs)
      #expect(store.entries.map(\.title) == originalEntryTitles)
      #expect(store.items(for: friend.id, kind: .like).map(\.title) == ["焼き魚"])
      #expect(store.items(for: me.id, kind: .hate).map(\.title) == ["梅干し"])
   }

   @Test("アップストアスクショモードはストア再読込後も復元できる")
   func appStoreScreenshotModeRestoresAfterReload() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      store.add("プリン", to: .like, personID: me.id)
      let originalPersonIDs = store.persons.map(\.id)

      store.setAppStoreScreenshotModeEnabled(true)

      let reloadedStore = LikeHateStore(defaults: context.defaults)
      let expectedSampleData = LikeHateStore.makeAppStoreScreenshotData(
         now: Date(),
         locale: Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
      )
      #expect(reloadedStore.isAppStoreScreenshotModeEnabled)
      #expect(reloadedStore.persons.map(\.displayName) == expectedSampleData.persons.map(\.displayName))

      reloadedStore.setAppStoreScreenshotModeEnabled(false)

      #expect(reloadedStore.isAppStoreScreenshotModeEnabled == false)
      #expect(reloadedStore.persons.map(\.id) == originalPersonIDs)
      #expect(reloadedStore.items(for: me.id, kind: .like).map(\.title) == ["プリン"])
   }

   @Test("アップストアスクショモードのサンプルデータは指定ロケールの文言を使う")
   func appStoreScreenshotSampleDataUsesSelectedLocale() throws {
      let now = Date(timeIntervalSince1970: 1_000)

      let japaneseSample = LikeHateStore.makeAppStoreScreenshotData(now: now, locale: Locale(identifier: "ja"))
      let englishSample = LikeHateStore.makeAppStoreScreenshotData(now: now, locale: Locale(identifier: "en"))
      let englishMe = try #require(englishSample.persons.first { $0.isMe })
      let englishAkari = englishSample.persons[1]

      #expect(japaneseSample.persons.map(\.displayName) == ["わたし", "あかり", "はると"])
      #expect(englishSample.persons.map(\.displayName) == ["Me", "Akari", "Haruto"])
      #expect(japaneseSample.entries.map(\.title).contains("おすし"))
      #expect(englishSample.entries.map(\.title).contains("Sushi"))
      #expect(englishSample.entries.map(\.title).contains("おすし") == false)

      let englishMeLikes = Set(englishSample.entries
         .filter { $0.personId == englishMe.id && $0.type == .like }
         .map(\.title))
      let englishMeHates = Set(englishSample.entries
         .filter { $0.personId == englishMe.id && $0.type == .hate }
         .map(\.title))
      let englishAkariLikes = Set(englishSample.entries
         .filter { $0.personId == englishAkari.id && $0.type == .like }
         .map(\.title))
      let englishAkariHates = Set(englishSample.entries
         .filter { $0.personId == englishAkari.id && $0.type == .hate }
         .map(\.title))

      #expect(englishMeLikes.intersection(englishAkariLikes).contains("Movie theater"))
      #expect(englishMeHates.intersection(englishAkariHates).contains("Too-spicy food"))
      #expect(englishMeLikes.subtracting(englishAkariLikes).contains("Night walks"))
      #expect(englishAkariLikes.subtracting(englishMeLikes).contains("Aquarium"))
   }
   #endif

   @Test("全削除は項目をリセットしわたしだけを作り直す")
   func deleteAllResetsPeopleAndEntries() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      let me = try #require(store.mePerson)
      _ = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage8))
      store.add("おすし", to: .like, personID: me.id)
      store.add("雨", to: .hate, personID: me.id)

      store.deleteAll()

      let resetMe = try #require(store.mePerson)
      #expect(store.persons.count == 1)
      #expect(resetMe.isMe)
      #expect(store.items(for: resetMe.id, kind: .like).isEmpty)
      #expect(store.items(for: resetMe.id, kind: .hate).isEmpty)
      #expect(resetMe.profileImageName == DefaultProfileImage.initialMeImage.rawValue)
   }

   @Test("全削除は旧項目配列も消す")
   func deleteAllClearsLegacyEntryArrays() throws {
      let context = try StoreTestContext(initialValues: { defaults in
         defaults.set(["おすし"], forKey: EntryKind.like.storageKey)
         defaults.set(["雨"], forKey: EntryKind.hate.storageKey)
      })
      defer { context.cleanup() }

      let store = context.store
      #expect(context.defaults.stringArray(forKey: EntryKind.like.storageKey) == ["おすし"])
      #expect(context.defaults.stringArray(forKey: EntryKind.hate.storageKey) == ["雨"])

      store.deleteAll()

      #expect(context.defaults.stringArray(forKey: EntryKind.like.storageKey) == nil)
      #expect(context.defaults.stringArray(forKey: EntryKind.hate.storageKey) == nil)
   }
}
