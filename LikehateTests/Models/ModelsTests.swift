import Foundation
import Testing
@testable import Likehate

struct PersonTests {
   @Test("Me display name ignores legacy stored names")
   func meDisplayNameIgnoresLegacyStoredNames() {
      let person = makePerson(name: "自分", isMe: true)

      #expect(person.name == "自分")
      #expect(person.displayName == String(localized: "DefaultMeName"))
      #expect(person.displayName != person.name)
   }

   @Test("Me display name stays fixed even when a custom name is stored")
   func meDisplayNameStaysFixedForCustomStoredName() {
      let person = makePerson(name: "じゅん", isMe: true)

      #expect(person.name == "じゅん")
      #expect(person.displayName == String(localized: "DefaultMeName"))
   }

   @Test("Other person display name uses the stored name")
   func otherPersonDisplayNameUsesStoredName() {
      let person = makePerson(name: "太郎", isMe: false)

      #expect(person.displayName == "太郎")
   }

   @Test("Profile image falls back to the first bundled image when stored value is invalid")
   func profileImageFallsBackForInvalidStoredValue() {
      var person = makePerson(name: "太郎", profileImageName: "missingAsset", isMe: false)

      #expect(person.profileImage == .defaultProfileImage)

      person.profileImage = .defaultProfileImage9
      #expect(person.profileImageName == DefaultProfileImage.defaultProfileImage9.rawValue)
      #expect(person.profileImage == .defaultProfileImage9)
   }
}

struct PersonIconSelectionStateTests {
   @Test("Beginning photo selection keeps the selected preset and existing photo state")
   func beginPhotoSelectionDoesNotResetPreset() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage7, hasExistingPhoto: true)

      state.beginPhotoSelection()

      #expect(state.selectedProfileImage == .defaultProfileImage7)
      #expect(state.removesExistingPhoto == false)
   }

   @Test("Selecting a preset profile image marks the existing photo for removal")
   func selectingPresetRemovesExistingPhoto() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage2, hasExistingPhoto: true)

      state.selectProfileImage(.defaultProfileImage9)

      #expect(state.selectedProfileImage == .defaultProfileImage9)
      #expect(state.removesExistingPhoto)
   }

   @Test("Selecting a cropped photo keeps the preset value and cancels pending photo removal")
   func selectingPhotoCancelsPendingPhotoRemoval() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage3, hasExistingPhoto: true)

      state.selectProfileImage(.defaultProfileImage12)
      state.didSelectPhoto()

      #expect(state.selectedProfileImage == .defaultProfileImage12)
      #expect(state.removesExistingPhoto == false)
   }
}

struct EntryKindTests {
   @Test("EntryKind exposes stable storage keys")
   func storageKeysAreStable() {
      #expect(EntryKind.like.storageKey == "OpenLikeKey")
      #expect(EntryKind.hate.storageKey == "OpenHateKey")
   }

   @Test("EntryKind exposes stable analytics names")
   func analyticsNamesAreStable() {
      #expect(EntryKind.like.analyticsName == "RegiLike")
      #expect(EntryKind.hate.analyticsName == "RegiHate")
   }
}

struct ComparisonCategoryTests {
   @Test("Comparison categories are partitioned by entry kind")
   func categoriesArePartitionedByEntryKind() {
      let likeCategories = ComparisonCategory.allCases.filter { $0.kind == .like }
      let hateCategories = ComparisonCategory.allCases.filter { $0.kind == .hate }

      #expect(likeCategories == [.firstOnlyLike, .commonLike, .secondOnlyLike])
      #expect(hateCategories == [.firstOnlyHate, .commonHate, .secondOnlyHate])
      #expect(Set(likeCategories + hateCategories) == Set(ComparisonCategory.allCases))
   }

   @Test("Person-specific comparison titles use display names")
   func personSpecificTitlesUseDisplayNames() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "太郎", isMe: false)

      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains(me.displayName))
      #expect(ComparisonCategory.secondOnlyHate.title(first: me, second: friend).contains(friend.displayName))
      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains("自分") == false)
   }
}

struct LocalizationTests {
   @Test("Japanese first-person localization is watashi")
   func japaneseFirstPersonLocalizationIsWatashi() {
      let japaneseMeName = String(localized: "DefaultMeName", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(japaneseMeName == "わたし")
   }

   @Test("Japanese person form copy matches the memo tone")
   func japanesePersonFormCopyMatchesMemoTone() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "AddPersonTitle", bundle: .main, locale: locale) == "人を追加")
      #expect(String(localized: "AddPersonHelpText", bundle: .main, locale: locale) == "好きなものや苦手なものを、あとで思い出せるように残しておけます。")
      #expect(String(localized: "PersonNamePlaceholder", bundle: .main, locale: locale) == "呼び方を書く")
      #expect(String(localized: "AddPersonSaveButton", bundle: .main, locale: locale) == "この人を追加")
      #expect(String(localized: "SavePersonChangesButton", bundle: .main, locale: locale) == "変更を保存")
      #expect(String(localized: "EditPersonHelpText", bundle: .main, locale: locale) == "呼び方やアイコンを変えられます。")
      #expect(String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat", bundle: .main, locale: locale), "あかり") == "あかりのこと")
      #expect(String(localized: "DeletePersonConfirmationTitle", bundle: .main, locale: locale) == "この人を削除しますか？")
      #expect(String(localized: "DeletePersonConfirmationMessage", bundle: .main, locale: locale) == "残していた好きなものや苦手なものも削除されます。")
      #expect(String(localized: "DeletePersonConfirmButton", bundle: .main, locale: locale) == "削除する")
   }

   @Test("Japanese comparison copy uses dislike instead of weak-point wording")
   func japaneseComparisonCopyUsesDislike() {
      let firstOnlyHate = String(localized: "ComparisonFirstOnlyHateFormat", bundle: .main, locale: Locale(identifier: "ja"))
      let secondOnlyHate = String(localized: "ComparisonSecondOnlyHateFormat", bundle: .main, locale: Locale(identifier: "ja"))
      let commonHate = String(localized: "ComparisonCommonHate", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(firstOnlyHate.contains("嫌い"))
      #expect(secondOnlyHate.contains("嫌い"))
      #expect(commonHate.contains("嫌い"))
      #expect(firstOnlyHate.contains("苦手") == false)
      #expect(secondOnlyHate.contains("苦手") == false)
      #expect(commonHate.contains("苦手") == false)
   }

   @Test("Comparison empty state localization keys resolve")
   func comparisonEmptyStateLocalizationKeysResolve() {
      let keys = [
         "ComparisonEmptyCommonHate",
         "ComparisonEmptyCommonHateMessage",
         "ComparisonEmptyCommonLike",
         "ComparisonEmptyCommonLikeMessage",
         "ComparisonEmptyFirstOnlyHateMessage",
         "ComparisonEmptyFirstOnlyLikeMessage",
         "ComparisonEmptySecondOnlyHateMessageFormat",
         "ComparisonEmptySecondOnlyLikeMessageFormat"
      ]

      for key in keys {
         let value = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         #expect(value.isEmpty == false)
         #expect(value != key)
      }
   }
}

struct DefaultProfileImageTests {
   @Test("Default profile images match bundled asset names")
   func profileImageAssetNamesAreStable() {
      let names = DefaultProfileImage.allCases.map(\.assetName)

      #expect(names.count == 19)
      #expect(names.first == "defaultProfileImage")
      #expect(names.last == "defaultProfileImage19")
      #expect(Set(names).count == names.count)
   }

   @Test("Default profile image option numbers are one-based and sequential")
   func profileImageOptionNumbersAreSequential() {
      let optionNumbers = DefaultProfileImage.allCases.map(\.optionNumber)

      #expect(optionNumbers == Array(1...DefaultProfileImage.allCases.count))
   }
}

struct AppTextSizeTests {
   @Test("Text size titles cover every selectable case")
   func textSizeTitlesExistForEveryCase() {
      #expect(AppTextSize.allCases.count == 5)

      for textSize in AppTextSize.allCases {
         #expect(String(describing: textSize.title).isEmpty == false)
      }
   }

   @Test("Home avatar size follows app text size")
   func homeAvatarSizeScalesWithTextSize() {
      let extraSmall = AppLayoutMetrics(textSize: .extraSmall).homePersonAvatarSize
      let standard = AppLayoutMetrics(textSize: .standard).homePersonAvatarSize
      let extraLarge = AppLayoutMetrics(textSize: .extraLarge).homePersonAvatarSize

      #expect(extraSmall < standard)
      #expect(standard < extraLarge)
   }

   @Test("Text size advancement clamps at the available bounds")
   func textSizeAdvancementClampsAtBounds() {
      #expect(AppTextSize.extraSmall.advanced(by: 2) == .standard)
      #expect(AppTextSize.small.advanced(by: 2) == .large)
      #expect(AppTextSize.standard.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.large.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.extraSmall.advanced(by: -2) == .extraSmall)
   }
}

private func makePerson(
   name: String,
   profileImageName: String? = DefaultProfileImage.defaultProfileImage.rawValue,
   isMe: Bool
) -> Person {
   Person(
      id: UUID(),
      name: name,
      profileImageName: profileImageName,
      photoFileName: nil,
      isMe: isMe,
      createdAt: Date(),
      updatedAt: Date(),
      sortOrder: 0
   )
}
