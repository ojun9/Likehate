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

   @Test("Me display name falls back for blank stored names")
   func meDisplayNameFallsBackForBlankStoredNames() {
      let person = makePerson(name: "   ", isMe: true)

      #expect(person.displayName == String(localized: "DefaultMeName"))
   }

   @Test("Me display name uses a custom stored name")
   func meDisplayNameUsesCustomStoredName() {
      let person = makePerson(name: "じゅん", isMe: true)

      #expect(person.name == "じゅん")
      #expect(person.displayName == "じゅん")
   }

   @Test("Other person display name uses the stored name")
   func otherPersonDisplayNameUsesStoredName() {
      let person = makePerson(name: "太郎", isMe: false)

      #expect(person.displayName == "太郎")
   }

   @Test("Other person display name trims incidental whitespace")
   func otherPersonDisplayNameTrimsWhitespace() {
      let person = makePerson(name: "  あかり  ", isMe: false)

      #expect(person.displayName == "あかり")
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

   @Test("Selecting a preset profile image without an existing photo does not mark removal")
   func selectingPresetWithoutExistingPhotoDoesNotRemovePhoto() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage2, hasExistingPhoto: false)

      state.selectProfileImage(.defaultProfileImage9)

      #expect(state.selectedProfileImage == .defaultProfileImage9)
      #expect(state.removesExistingPhoto == false)
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

struct PersonFormModeTests {
   @Test("Person form mode covers add, friend edit, and me edit titles")
   func titlesCoverAddFriendAndMeEdit() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "あかり", isMe: false)

      #expect(PersonFormMode.add.id == "add")
      #expect(PersonFormMode.add.title == String(localized: "AddPersonTitle"))
      #expect(PersonFormMode.add.allowsNameEditing)
      #expect(PersonFormMode.edit(friend).id == friend.id.uuidString)
      #expect(PersonFormMode.edit(friend).title == String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat"), friend.displayName))
      #expect(PersonFormMode.edit(me).title == String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat"), me.displayName))
      #expect(PersonFormMode.edit(me).title.contains("自分") == false)
      #expect(PersonFormMode.edit(friend).allowsNameEditing)
      #expect(PersonFormMode.edit(me).allowsNameEditing)
   }
}

struct PersonNameSubmitActionTests {
   @Test("Done submit only dismisses the keyboard")
   func doneSubmitOnlyDismissesKeyboard() {
      #expect(PersonNameSubmitAction.done.action() == .dismissKeyboard)
   }
}

struct PersonNameRulesTests {
   @Test("Person name limit is forty characters")
   func personNameLimitIsFortyCharacters() {
      #expect(PersonNameRules.maxLength == 40)
   }

   @Test("Person names are trimmed and limited")
   func personNamesAreTrimmedAndLimited() {
      let rawName = "  " + String(repeating: "あ", count: 41) + "  "
      let sanitizedName = PersonNameRules.sanitized(rawName)

      #expect(sanitizedName.count == 40)
      #expect(sanitizedName == String(repeating: "あ", count: 40))
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

   @Test("Japanese entry actions use watashi and dislike wording")
   func japaneseEntryActionsUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "LikeInputButtonMe", bundle: .main, locale: locale) == "わたしはこれが好き")
      #expect(String(localized: "HateInputButtonMe", bundle: .main, locale: locale) == "これは嫌い")
      #expect(String.localizedStringWithFormat(String(localized: "LikeInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが好き")
      #expect(String.localizedStringWithFormat(String(localized: "HateInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが嫌い")
   }

   @Test("Japanese list titles use watashi and dislike wording")
   func japaneseListTitlesUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "MyLikesTitle", bundle: .main, locale: locale) == "わたしの好きなもの")
      #expect(String(localized: "MyHatesTitle", bundle: .main, locale: locale) == "わたしの嫌いなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonLikesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の好きなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonHatesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の嫌いなもの")
   }

   @Test("Person-aware entry copy uses display names and not legacy me wording")
   func personAwareEntryCopyUsesDisplayNames() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "太郎", isMe: false)

      #expect(EntryKind.like.inputButtonTitle(for: me) == String(localized: "LikeInputButtonMe"))
      #expect(EntryKind.hate.inputButtonTitle(for: me) == String(localized: "HateInputButtonMe"))
      #expect(EntryKind.like.listTitle(for: me) == String(localized: "MyLikesTitle"))
      #expect(EntryKind.hate.listTitle(for: me) == String(localized: "MyHatesTitle"))
      #expect(EntryKind.like.inputButtonTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.hate.inputButtonTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.like.listTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.hate.listTitle(for: friend).contains(friend.displayName))
      #expect(EntryKind.like.listTitle(for: me).contains("自分") == false)
      #expect(EntryKind.hate.listTitle(for: me).contains("自分") == false)
   }
}

struct EntryPreviewItemsTests {
   @Test("Entry previews use the first items from the current order")
   func previewsUseFirstItemsFromCurrentOrder() {
      let personID = UUID()
      let items = [
         makeItem(title: "おすし", personID: personID, sortOrder: 0),
         makeItem(title: "カレー", personID: personID, sortOrder: 1),
         makeItem(title: "映画", personID: personID, sortOrder: 2),
         makeItem(title: "散歩", personID: personID, sortOrder: 3)
      ]

      let previewTitles = EntryPreviewItems.items(from: items).map(\.title)

      #expect(previewTitles == ["おすし", "カレー"])
   }

   @Test("Entry previews can be limited and reject empty limits")
   func previewsRespectLimit() {
      let personID = UUID()
      let items = [
         makeItem(title: "おすし", personID: personID, sortOrder: 0),
         makeItem(title: "カレー", personID: personID, sortOrder: 1),
         makeItem(title: "映画", personID: personID, sortOrder: 2)
      ]

      #expect(EntryPreviewItems.maxCount == 2)
      #expect(EntryPreviewItems.items(from: items, limit: 1).map(\.title) == ["おすし"])
      #expect(EntryPreviewItems.items(from: items, limit: 0).isEmpty)
   }
}

struct EntryLottieSelectionTests {
   @Test("Entry lottie names are grouped by entry kind")
   func lottieNamesAreGroupedByEntryKind() {
      #expect(EntryLottieSelection.names(for: .like) == ["MoreHarts", "heart1", "heart2"])
      #expect(EntryLottieSelection.names(for: .hate) == ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"])
      #expect(EntryLottieSelection.fallbackName(for: .like) == "MoreHarts")
      #expect(EntryLottieSelection.fallbackName(for: .hate) == "fish")
   }

   @Test("Entry lottie selection avoids the current animation when possible")
   func lottieSelectionAvoidsCurrentAnimation() {
      for name in EntryLottieSelection.names(for: .like) {
         #expect(EntryLottieSelection.randomName(for: .like, excluding: name) != name)
      }

      for name in EntryLottieSelection.names(for: .hate) {
         #expect(EntryLottieSelection.randomName(for: .hate, excluding: name) != name)
      }
   }

   @Test("Entry lottie selection stays within each kind's candidates")
   func lottieSelectionStaysWithinCandidates() {
      let likeNames = EntryLottieSelection.names(for: .like)
      let hateNames = EntryLottieSelection.names(for: .hate)

      #expect(likeNames.contains(EntryLottieSelection.randomName(for: .like, excluding: "missing")))
      #expect(hateNames.contains(EntryLottieSelection.randomName(for: .hate, excluding: "missing")))
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

struct ComparisonResultSectionGroupTests {
   @Test("Comparison result groups are the only top-level result sections")
   func resultGroupsAreTheOnlyTopLevelSections() {
      let groups = ComparisonResultSectionGroup.ordered

      #expect(groups.map(\.titleKey) == [
         "ComparisonTogetherTitle",
         "ComparisonAvoidTitle",
         "ComparisonDifferencesTitle"
      ])
      #expect(groups.map(\.id) == [.together, .avoid, .differences])
      #expect(groups.contains { $0.titleKey.hasPrefix("ComparisonSummary") } == false)
   }

   @Test("Comparison result groups cover every category once")
   func resultGroupsCoverEveryCategoryOnce() {
      let categories = ComparisonResultSectionGroup.ordered.flatMap(\.categories)

      #expect(categories.count == ComparisonCategory.allCases.count)
      #expect(Set(categories) == Set(ComparisonCategory.allCases))
   }

   @Test("Comparison result groups filter their own sections")
   func resultGroupsFilterTheirOwnSections() throws {
      let sections = ComparisonCategory.allCases.map { category in
         ComparisonSection(category: category, titles: [category.rawValue])
      }
      let together = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .together })
      let avoid = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .avoid })
      let differences = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .differences })

      #expect(together.sections(from: sections).map(\.category) == [.commonLike])
      #expect(avoid.sections(from: sections).map(\.category) == [.commonHate])
      #expect(differences.sections(from: sections).map(\.category) == [.firstOnlyLike, .secondOnlyLike, .firstOnlyHate, .secondOnlyHate])
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
      #expect(String(localized: "AddPersonSaveButton", bundle: .main, locale: locale) == "追加")
      #expect(String(localized: "ProfileImageSectionTitle", bundle: .main, locale: locale) == "プリセット")
      #expect(String.localizedStringWithFormat(String(localized: "ProfileImageOptionFormat", bundle: .main, locale: locale), 3) == "プリセット 3")
      #expect(String(localized: "SavePersonChangesButton", bundle: .main, locale: locale) == "保存")
      #expect(String(localized: "EditPersonHelpText", bundle: .main, locale: locale) == "呼び方やアイコンを変えられます。")
      #expect(String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat", bundle: .main, locale: locale), "あかり") == "あかりのこと")
      #expect(String(localized: "DeletePersonConfirmationTitle", bundle: .main, locale: locale) == "この人を削除しますか？")
      #expect(String(localized: "DeletePersonConfirmationMessage", bundle: .main, locale: locale) == "残していた好きなものや苦手なものも削除されます。")
      #expect(String(localized: "DeletePersonConfirmButton", bundle: .main, locale: locale) == "削除する")
   }

   @Test("English person form copy resolves to user-facing strings")
   func englishPersonFormCopyResolves() {
      let locale = Locale(identifier: "en")
      let keys = [
         "AddPersonTitle",
         "AddPersonHelpText",
         "PersonNamePlaceholder",
         "AddPersonSaveButton",
         "ProfileImageSectionTitle",
         "ProfileImageOptionFormat",
         "SavePersonChangesButton",
         "EditPersonHelpText",
         "DeletePersonConfirmationTitle",
         "DeletePersonConfirmationMessage",
         "DeletePersonConfirmButton"
      ]

      for key in keys {
         let value = String(localized: String.LocalizationValue(key), bundle: .main, locale: locale)
         #expect(value.isEmpty == false)
         #expect(value != key)
      }

      let title = String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat", bundle: .main, locale: locale), "Akari")
      #expect(title.contains("Akari"))
      #expect(title != "EditPersonTitleFormat")
   }

   @Test("Deprecated person edit copy no longer resolves to the old mechanical wording")
   func deprecatedPersonEditCopyAvoidsMechanicalWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "EditPersonButton", bundle: .main, locale: locale) != "人を編集")
      #expect(String(localized: "EditPersonTitle", bundle: .main, locale: locale) != "人を編集")
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

   @Test("Japanese common comparison copy uses both wording")
   func japaneseCommonComparisonCopyUsesBothWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "ComparisonCommonLike", bundle: .main, locale: locale) == "どっちも好き")
      #expect(String(localized: "ComparisonCommonHate", bundle: .main, locale: locale) == "どっちも嫌い")
      #expect(String(localized: "ComparisonEmptyCommonLike", bundle: .main, locale: locale) == "どっちも好きなものはまだありません")
      #expect(String(localized: "ComparisonEmptyCommonHate", bundle: .main, locale: locale) == "どっちも嫌いなものはまだありません")
   }

   @Test("Japanese comparison difference section uses relationship wording")
   func japaneseComparisonDifferenceSectionUsesRelationshipWording() {
      let title = String(localized: "ComparisonDifferencesTitle", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(title == "ふたりの違い")
      #expect(title != "違いを見る")
   }

   @Test("Debug menu localization keys resolve")
   func debugMenuLocalizationKeysResolve() {
      let keys = [
         "DebugSectionTitle",
         "AppStoreScreenshotModeTitle",
         "AppStoreScreenshotModeSubtitle"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
      }
   }

   @Test("Japanese premium copy explains one-time purchase and free limit")
   func japanesePremiumCopyExplainsOneTimePurchaseAndFreeLimit() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "PremiumTitle", bundle: .main, locale: locale) == "プレミアム")
      #expect(String(localized: "PremiumHeroTitle", bundle: .main, locale: locale) == "もっと人を追加できます")
      #expect(String(localized: "PremiumFreeLimitMessage", bundle: .main, locale: locale) == "無料版では、わたしを含めて3人まで登録できます。")
      #expect(String(localized: "PremiumUpgradeMessage", bundle: .main, locale: locale) == "プレミアムにすると、4人以上の好き嫌いも残せて、広告も非表示になります。")
      #expect(String(localized: "PremiumOneTimeNote", bundle: .main, locale: locale) == "月額ではありません。一度の購入で使えます。")
      #expect(String(localized: "PremiumPurchaseButton", bundle: .main, locale: locale) == "プレミアムを購入")
      #expect(String(localized: "PremiumRestoreButton", bundle: .main, locale: locale) == "購入を復元")
      #expect(String(localized: "PremiumCloseButton", bundle: .main, locale: locale) == "あとで")
      #expect(String(localized: "PremiumSettingsSubtitle", bundle: .main, locale: locale) == "人数制限解除・広告非表示")
      #expect(String(localized: "PremiumPurchasedStatus", bundle: .main, locale: locale) == "購入済み")
   }

   @Test("Premium and restore localization keys resolve")
   func premiumAndRestoreLocalizationKeysResolve() {
      let keys = [
         "PremiumBenefitLifetime",
         "PremiumBenefitNoAds",
         "PremiumBenefitPeople",
         "PremiumHeroMessage",
         "PremiumPurchaseButtonWithPriceFormat",
         "PremiumPurchaseDeferredMessage",
         "PremiumPurchaseDeferredTitle",
         "PremiumPurchaseFailedTitle",
         "PremiumPurchaseSucceededMessage",
         "PremiumPurchaseSucceededTitle",
         "RestorePurchaseEmptyMessage",
         "RestorePurchaseEmptyTitle",
         "RestorePurchaseFailedTitle",
         "RestorePurchaseSucceededMessage",
         "RestorePurchaseSucceededTitle"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
      }
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

   @Test("Entry empty list localization keys resolve")
   func entryEmptyListLocalizationKeysResolve() {
      let keys = [
         "EmptyLikesTitle",
         "EmptyLikesMessage",
         "EmptyHatesTitle",
         "EmptyHatesMessage"
      ]

      for key in keys {
         let japaneseValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "ja"))
         let englishValue = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))

         #expect(japaneseValue.isEmpty == false)
         #expect(englishValue.isEmpty == false)
         #expect(japaneseValue != key)
         #expect(englishValue != key)
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

   @Test("Default profile image picks the first unused image")
   func profileImagePicksFirstUnusedImage() {
      let usedImages: Set<DefaultProfileImage> = [
         .defaultProfileImage,
         .defaultProfileImage2,
         .defaultProfileImage3
      ]

      #expect(DefaultProfileImage.firstAvailable(excluding: usedImages) == .defaultProfileImage4)
   }

   @Test("Default profile image falls back when every image is already used")
   func profileImageFallsBackWhenEveryImageIsUsed() {
      #expect(DefaultProfileImage.firstAvailable(excluding: Set(DefaultProfileImage.allCases)) == .defaultProfileImage)
   }
}

struct AdDisplayPolicyTests {
   @Test("List ads show only for free users with list items")
   func listAdsShowOnlyForFreeUsersWithItems() {
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: true))
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: false) == false)
   }

   @Test("List ads are hidden for ad-removed and premium users")
   func listAdsAreHiddenForAdRemovedAndPremiumUsers() {
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: false).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: true).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: true).showsListAd(hasItems: true) == false)
   }
}

struct PremiumAccessPolicyTests {
   @Test("Free person limit includes me and stops at three people")
   func freePersonLimitIncludesMeAndStopsAtThreePeople() {
      #expect(PremiumAccessPolicy.freePersonLimit == 3)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 1).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 2).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 3).canAddPerson == false)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 4).canAddPerson == false)
   }

   @Test("Premium and legacy ad removal both unlock person limit")
   func premiumAndLegacyAdRemovalBothUnlockPersonLimit() {
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: false, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: true, personCount: 8).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).hasPremiumAccess)
   }
}

struct AppTextSizeTests {
   @Test("Text sizes are ordered from smallest to largest")
   func textSizesAreOrderedFromSmallestToLargest() {
      #expect(AppTextSize.allCases == [.extraSmall, .small, .standard, .large, .extraLarge])
   }

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

   @Test("Layout metrics expand with selected text size")
   func layoutMetricsExpandWithSelectedTextSize() {
      let metrics = AppTextSize.allCases.map(AppLayoutMetrics.init(textSize:))

      #expect(metrics.map(\.screenPadding) == [16, 18, 20, 22, 22])
      #expect(metrics.map(\.cardPadding) == [14, 16, 18, 20, 22])
      #expect(metrics.map(\.cardSpacing) == [10, 12, 14, 16, 18])
      #expect(metrics.map(\.sectionSpacing) == [20, 22, 26, 30, 34])
      #expect(metrics.map(\.rowMinHeight) == [48, 52, 58, 64, 70])
      #expect(metrics.map(\.personCardMinHeight) == [104, 112, 124, 136, 148])
      #expect(metrics.map(\.homePersonAvatarSize) == [78, 84, 93, 102, 111])
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

private func makeItem(
   title: String,
   personID: UUID,
   kind: EntryKind = .like,
   sortOrder: Int
) -> LikeDislikeItem {
   LikeDislikeItem(
      id: UUID(),
      personId: personID,
      type: kind,
      title: title,
      note: nil,
      createdAt: Date(),
      updatedAt: Date(),
      sortOrder: sortOrder
   )
}
