import Foundation
import FirebaseAnalytics
import Testing
@testable import Likehate

struct PersonTests {
   @Test("わたしの表示名は古い保存名を使わない")
   func meDisplayNameIgnoresLegacyStoredNames() {
      let person = makePerson(name: "自分", isMe: true)

      #expect(person.name == "自分")
      #expect(person.displayName == String(localized: "DefaultMeName"))
      #expect(person.displayName != person.name)
   }

   @Test("わたしの表示名は空の保存名ならデフォルトに戻る")
   func meDisplayNameFallsBackForBlankStoredNames() {
      let person = makePerson(name: "   ", isMe: true)

      #expect(person.displayName == String(localized: "DefaultMeName"))
   }

   @Test("わたしの表示名は変更した保存名を使う")
   func meDisplayNameUsesCustomStoredName() {
      let person = makePerson(name: "じゅん", isMe: true)

      #expect(person.name == "じゅん")
      #expect(person.displayName == "じゅん")
   }

   @Test("他人の表示名は保存名を使う")
   func otherPersonDisplayNameUsesStoredName() {
      let person = makePerson(name: "太郎", isMe: false)

      #expect(person.displayName == "太郎")
   }

   @Test("他人の表示名は余分な空白を取り除く")
   func otherPersonDisplayNameTrimsWhitespace() {
      let person = makePerson(name: "  あかり  ", isMe: false)

      #expect(person.displayName == "あかり")
   }

   @Test("プロフィール画像は不正な保存値なら最初の同梱画像に戻る")
   func profileImageFallsBackForInvalidStoredValue() {
      var person = makePerson(name: "太郎", profileImageName: "missingAsset", isMe: false)

      #expect(person.profileImage == .defaultProfileImage)

      person.profileImage = .defaultProfileImage9
      #expect(person.profileImageName == DefaultProfileImage.defaultProfileImage9.rawValue)
      #expect(person.profileImage == .defaultProfileImage9)
   }
}

struct PersonIconSelectionStateTests {
   @Test("写真選択開始では選択中プリセットと既存写真状態を保つ")
   func beginPhotoSelectionDoesNotResetPreset() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage7, hasExistingPhoto: true)

      state.beginPhotoSelection()

      #expect(state.selectedProfileImage == .defaultProfileImage7)
      #expect(state.removesExistingPhoto == false)
   }

   @Test("プリセット画像を選ぶと既存写真を削除予定にする")
   func selectingPresetRemovesExistingPhoto() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage2, hasExistingPhoto: true)

      state.selectProfileImage(.defaultProfileImage9)

      #expect(state.selectedProfileImage == .defaultProfileImage9)
      #expect(state.removesExistingPhoto)
   }

   @Test("既存写真がない状態でプリセット画像を選んでも削除予定にしない")
   func selectingPresetWithoutExistingPhotoDoesNotRemovePhoto() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage2, hasExistingPhoto: false)

      state.selectProfileImage(.defaultProfileImage9)

      #expect(state.selectedProfileImage == .defaultProfileImage9)
      #expect(state.removesExistingPhoto == false)
   }

   @Test("クロップ済み写真を選ぶとプリセット値を保ち写真削除予定を取り消す")
   func selectingPhotoCancelsPendingPhotoRemoval() {
      var state = PersonIconSelectionState(selectedProfileImage: .defaultProfileImage3, hasExistingPhoto: true)

      state.selectProfileImage(.defaultProfileImage12)
      state.didSelectPhoto()

      #expect(state.selectedProfileImage == .defaultProfileImage12)
      #expect(state.removesExistingPhoto == false)
   }
}

struct PersonFormModeTests {
   @Test("人物フォームモードは追加と他人編集とわたし編集のタイトルを網羅する")
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
   @Test("完了送信はキーボードを閉じるだけにする")
   func doneSubmitOnlyDismissesKeyboard() {
      #expect(PersonNameSubmitAction.done.action() == .dismissKeyboard)
   }
}

struct PersonNameRulesTests {
   @Test("人物名の上限は40文字にする")
   func personNameLimitIsFortyCharacters() {
      #expect(PersonNameRules.maxLength == 40)
   }

   @Test("人物名は空白を取り除いて文字数制限する")
   func personNamesAreTrimmedAndLimited() {
      let rawName = "  " + String(repeating: "あ", count: 41) + "  "
      let sanitizedName = PersonNameRules.sanitized(rawName)

      #expect(sanitizedName.count == 40)
      #expect(sanitizedName == String(repeating: "あ", count: 40))
   }
}

struct EntryKindTests {
   @Test("入力種別の保存キーは安定している")
   func storageKeysAreStable() {
      #expect(EntryKind.like.storageKey == "OpenLikeKey")
      #expect(EntryKind.hate.storageKey == "OpenHateKey")
   }

   @Test("入力種別の分析名は安定している")
   func analyticsNamesAreStable() {
      #expect(EntryKind.like.analyticsName == "RegiLike")
      #expect(EntryKind.hate.analyticsName == "RegiHate")
   }

   @Test("日本語の入力文言はわたしと嫌い表記を使う")
   func japaneseEntryActionsUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "LikeInputButtonMe", bundle: .main, locale: locale) == "わたしはこれが好き")
      #expect(String(localized: "HateInputButtonMe", bundle: .main, locale: locale) == "これは嫌い")
      #expect(String.localizedStringWithFormat(String(localized: "LikeInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが好き")
      #expect(String.localizedStringWithFormat(String(localized: "HateInputButtonPersonFormat", bundle: .main, locale: locale), "太郎") == "太郎はこれが嫌い")
   }

   @Test("日本語の一覧タイトルはわたしと嫌い表記を使う")
   func japaneseListTitlesUseWatashiAndDislikeWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "MyLikesTitle", bundle: .main, locale: locale) == "わたしの好きなもの")
      #expect(String(localized: "MyHatesTitle", bundle: .main, locale: locale) == "わたしの嫌いなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonLikesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の好きなもの")
      #expect(String.localizedStringWithFormat(String(localized: "PersonHatesTitleFormat", bundle: .main, locale: locale), "太郎") == "太郎の嫌いなもの")
   }

   @Test("人物別の入力文言は表示名を使い古い自分表記を使わない")
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
   @Test("入力プレビューは現在の並び順の先頭項目を使う")
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

   @Test("入力プレビューは件数制限でき空の制限を拒否する")
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
   @Test("入力アニメーション名は入力種別ごとにまとまっている")
   func lottieNamesAreGroupedByEntryKind() {
      #expect(EntryLottieSelection.names(for: .like) == ["MoreHarts", "heart1", "heart2"])
      #expect(EntryLottieSelection.names(for: .hate) == ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"])
      #expect(EntryLottieSelection.fallbackName(for: .like) == "MoreHarts")
      #expect(EntryLottieSelection.fallbackName(for: .hate) == "fish")
   }

   @Test("入力アニメーション選択は可能なら現在のアニメーションを避ける")
   func lottieSelectionAvoidsCurrentAnimation() {
      for name in EntryLottieSelection.names(for: .like) {
         #expect(EntryLottieSelection.randomName(for: .like, excluding: name) != name)
      }

      for name in EntryLottieSelection.names(for: .hate) {
         #expect(EntryLottieSelection.randomName(for: .hate, excluding: name) != name)
      }
   }

   @Test("入力アニメーション選択は各種別の候補内に収まる")
   func lottieSelectionStaysWithinCandidates() {
      let likeNames = EntryLottieSelection.names(for: .like)
      let hateNames = EntryLottieSelection.names(for: .hate)

      #expect(likeNames.contains(EntryLottieSelection.randomName(for: .like, excluding: "missing")))
      #expect(hateNames.contains(EntryLottieSelection.randomName(for: .hate, excluding: "missing")))
   }
}

struct ComparisonCategoryTests {
   @Test("比較カテゴリは入力種別ごとに分かれる")
   func categoriesArePartitionedByEntryKind() {
      let likeCategories = ComparisonCategory.allCases.filter { $0.kind == .like }
      let hateCategories = ComparisonCategory.allCases.filter { $0.kind == .hate }

      #expect(likeCategories == [.firstOnlyLike, .commonLike, .secondOnlyLike])
      #expect(hateCategories == [.firstOnlyHate, .commonHate, .secondOnlyHate])
      #expect(Set(likeCategories + hateCategories) == Set(ComparisonCategory.allCases))
   }

   @Test("人物別の比較タイトルは表示名を使う")
   func personSpecificTitlesUseDisplayNames() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "太郎", isMe: false)

      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains(me.displayName))
      #expect(ComparisonCategory.secondOnlyHate.title(first: me, second: friend).contains(friend.displayName))
      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains("自分") == false)
   }
}

struct ComparisonResultSectionGroupTests {
   @Test("比較結果グループだけが最上位セクションになる")
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

   @Test("比較結果グループは全カテゴリを一度ずつ網羅する")
   func resultGroupsCoverEveryCategoryOnce() {
      let categories = ComparisonResultSectionGroup.ordered.flatMap(\.categories)

      #expect(categories.count == ComparisonCategory.allCases.count)
      #expect(Set(categories) == Set(ComparisonCategory.allCases))
   }

   @Test("比較結果グループは自分のセクションだけを絞り込む")
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
   @Test("日本語の一人称ローカライズはわたしになる")
   func japaneseFirstPersonLocalizationIsWatashi() {
      let japaneseMeName = String(localized: "DefaultMeName", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(japaneseMeName == "わたし")
   }

   @Test("日本語の人物フォーム文言はメモ帳らしいトーンにする")
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

   @Test("英語の人物フォーム文言はユーザー向け文字列に解決される")
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

   @Test("廃止済みの人物編集文言は古い無機質な表記に解決されない")
   func deprecatedPersonEditCopyAvoidsMechanicalWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "EditPersonButton", bundle: .main, locale: locale) != "人を編集")
      #expect(String(localized: "EditPersonTitle", bundle: .main, locale: locale) != "人を編集")
   }

   @Test("日本語の比較文言は苦手ではなく嫌い表記を使う")
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

   @Test("日本語の共通比較文言はどっちも表記を使う")
   func japaneseCommonComparisonCopyUsesBothWording() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "ComparisonCommonLike", bundle: .main, locale: locale) == "どっちも好き")
      #expect(String(localized: "ComparisonCommonHate", bundle: .main, locale: locale) == "どっちも嫌い")
      #expect(String(localized: "ComparisonEmptyCommonLike", bundle: .main, locale: locale) == "どっちも好きなものはまだありません")
      #expect(String(localized: "ComparisonEmptyCommonHate", bundle: .main, locale: locale) == "どっちも嫌いなものはまだありません")
   }

   @Test("日本語の比較差分セクションはふたりの違い表記を使う")
   func japaneseComparisonDifferenceSectionUsesRelationshipWording() {
      let title = String(localized: "ComparisonDifferencesTitle", bundle: .main, locale: Locale(identifier: "ja"))

      #expect(title == "ふたりの違い")
      #expect(title != "違いを見る")
   }

   @Test("デバッグメニューのローカライズキーが解決される")
   func debugMenuLocalizationKeysResolve() {
      let keys = [
         "DebugSectionTitle",
         "AppStoreScreenshotModeTitle",
         "AppStoreScreenshotModeSubtitle",
         "RevenueCatDebugTitle",
         "RevenueCatDebugSubtitle"
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

   @Test("日本語の買い切りプレミアム文言は買い切りと無料上限を説明する")
   func japanesePremiumCopyExplainsOneTimePurchaseAndFreeLimit() {
      let locale = Locale(identifier: "ja")

      #expect(String(localized: "PremiumBadge", bundle: .main, locale: locale) == "買い切り")
      #expect(String(localized: "PremiumTitle", bundle: .main, locale: locale) == "買い切りプレミアム")
      #expect(String(localized: "PremiumHeroTitle", bundle: .main, locale: locale) == "もっと大切な人を追加できます")
      #expect(String(localized: "PremiumFreeLimitMessage", bundle: .main, locale: locale) == "無料版では、あなたを含めて3人まで登録できます。")
      #expect(String(localized: "PremiumUpgradeMessage", bundle: .main, locale: locale) == "買い切りプレミアムにすると、4人以上の好き嫌いも残せて、広告も非表示になります。")
      #expect(String(localized: "PremiumOneTimeNote", bundle: .main, locale: locale) == "月額ではありません。一度の購入で使えます。")
      #expect(String(localized: "PremiumComparisonTitle", bundle: .main, locale: locale) == "できることが広がります")
      #expect(String(localized: "PremiumFreePlanTitle", bundle: .main, locale: locale) == "無料版")
      #expect(String(localized: "PremiumFreePlanBadge", bundle: .main, locale: locale) == "現在")
      #expect(String(localized: "PremiumFreePlanMessage", bundle: .main, locale: locale) == "3人まで登録できます。一覧画面には広告が表示されます。")
      #expect(String(localized: "PremiumPaidPlanTitle", bundle: .main, locale: locale) == "買い切りプレミアム")
      #expect(String(localized: "PremiumPaidPlanMessage", bundle: .main, locale: locale) == "4人以上追加できて、一覧画面の広告も非表示になります。")
      #expect(String(localized: "PremiumPriceLoading", bundle: .main, locale: locale) == "価格を読み込み中")
      #expect(String(localized: "PremiumPurchaseButton", bundle: .main, locale: locale) == "買い切りプレミアムを購入")
      #expect(String(format: String(localized: "PremiumPurchaseButtonWithPriceFormat", bundle: .main, locale: locale), "¥800") == "買い切りプレミアムを購入（¥800）")
      #expect(String(localized: "PremiumRestoreButton", bundle: .main, locale: locale) == "購入を復元")
      #expect(String(localized: "PremiumCloseButton", bundle: .main, locale: locale) == "あとで")
      #expect(String(localized: "PremiumSettingsSubtitle", bundle: .main, locale: locale) == "人数制限解除・広告非表示")
      #expect(String(localized: "PremiumPurchasedStatus", bundle: .main, locale: locale) == "購入済み")
   }

   @Test("プレミアムと復元のローカライズキーが解決される")
   func premiumAndRestoreLocalizationKeysResolve() {
      let keys = [
         "PremiumBadge",
         "PremiumBenefitLifetime",
         "PremiumBenefitNoAds",
         "PremiumBenefitPeople",
         "PremiumComparisonTitle",
         "PremiumFreePlanBadge",
         "PremiumFreePlanMessage",
         "PremiumFreePlanTitle",
         "PremiumPaidPlanMessage",
         "PremiumPaidPlanTitle",
         "PremiumPriceLoading",
         "PremiumPurchaseButtonWithPriceFormat",
         "PremiumPurchaseDeferredMessage",
         "PremiumPurchaseDeferredTitle",
         "PremiumPurchaseFailedTitle",
         "PremiumPurchaseSucceededMessage",
         "PremiumPurchaseSucceededTitle",
         "PremiumPurchaseUnavailableMessage",
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

   @Test("比較空状態のローカライズキーが解決される")
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

   @Test("入力一覧空状態のローカライズキーが解決される")
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

struct RevenueCatContractsTests {
   @Test("レベニューキャット契約は設定済みの公開アイオーエス開発キットキーを使う")
   func revenueCatContractUsesConfiguredPublicIOSSDKKey() {
      #expect(LikehateRevenueCatContracts.publicSDKKey == "appl_KjaunKCKXyQMEbmdzqjXhbbiEkG")
      #expect(LikehateRevenueCatContracts.premiumProductID == "NO_ADS_LIKEHATE")
      #expect(LikehateRevenueCatContracts.premiumEntitlementID == "premium")
   }
}

struct FAEventTests {
   @Test("画面表示イベントはFirebase標準のscreen_viewを使う")
   func screenViewUsesFirebaseScreenEvent() {
      let event = FAEvent.screenView(.premium, parameters: [.source: "settings"])

      #expect(event.name == AnalyticsEventScreenView)
      #expect(event.parameters?[AnalyticsParameterScreenName] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?[AnalyticsParameterScreenClass] as? String == FAScreen.premium.rawValue)
      #expect(event.parameters?["source"] as? String == "settings")
   }

   @Test("FAEvent名はFirebaseのカスタムイベント制約に収まる")
   func eventNamesFitFirebaseCustomEventRules() {
      let allowedScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")

      for eventName in FAEventName.allCases.map(\.rawValue) {
         #expect(eventName.count <= 40)
         #expect(eventName.first?.isLetter == true)
         #expect(eventName.unicodeScalars.allSatisfy { allowedScalars.contains($0) })
      }
   }

   @Test("買い切りプレミアム購入イベントは商品IDと価格表示を含む")
   func premiumPurchaseEventIncludesProductIDAndPriceText() {
      let event = FAEvent.purchase(
         productID: LikehateRevenueCatContracts.premiumProductID,
         price: "¥800",
         parameters: [.source: "purchase"]
      )

      #expect(event.name == AnalyticsEventPurchase)
      #expect(event.parameters?[AnalyticsParameterItemID] as? String == "NO_ADS_LIKEHATE")
      #expect(event.parameters?[AnalyticsParameterItemName] as? String == "premium_lifetime")
      #expect(event.parameters?["price_text"] as? String == "¥800")
      #expect(event.parameters?["source"] as? String == "purchase")
   }

   @Test("FAParameterは送信キーを重複なく一覧化する")
   func parameterKeysAreListedAndUnique() {
      let keys = FAParameter.allCases.map(\.key)

      #expect(keys.count == Set(keys).count)
      #expect(keys.contains("source"))
      #expect(keys.contains("person_count"))
      #expect(keys.contains("product_id"))
      #expect(keys.contains(AnalyticsParameterScreenName))
      #expect(keys.contains(AnalyticsParameterItemID))
   }

   @Test("主要な課金イベント名がFAEventに定義されている")
   func premiumLifecycleEventsAreDefined() {
      let names = Set(FAEventName.allCases.map(\.rawValue))

      #expect(names.contains("premium_product_fetch_started"))
      #expect(names.contains("premium_product_fetch_succeeded"))
      #expect(names.contains("premium_purchase_started"))
      #expect(names.contains("premium_purchase_succeeded"))
      #expect(names.contains("premium_purchase_cancelled"))
      #expect(names.contains("premium_purchase_failed"))
      #expect(names.contains("premium_restore_started"))
      #expect(names.contains("premium_restore_succeeded"))
      #expect(names.contains("premium_restore_empty"))
      #expect(names.contains("premium_entitlement_updated"))
   }
}

struct DefaultProfileImageTests {
   @Test("デフォルトプロフィール画像は同梱アセット名と一致する")
   func profileImageAssetNamesAreStable() {
      let names = DefaultProfileImage.allCases.map(\.assetName)

      #expect(names.count == 19)
      #expect(names.first == "defaultProfileImage")
      #expect(names.last == "defaultProfileImage19")
      #expect(Set(names).count == names.count)
   }

   @Test("デフォルトプロフィール画像の番号は1始まりで連番になる")
   func profileImageOptionNumbersAreSequential() {
      let optionNumbers = DefaultProfileImage.allCases.map(\.optionNumber)

      #expect(optionNumbers == Array(1...DefaultProfileImage.allCases.count))
   }

   @Test("デフォルトプロフィール画像は未使用の最初の画像を選ぶ")
   func profileImagePicksFirstUnusedImage() {
      let usedImages: Set<DefaultProfileImage> = [
         .defaultProfileImage,
         .defaultProfileImage2,
         .defaultProfileImage3
      ]

      #expect(DefaultProfileImage.firstAvailable(excluding: usedImages) == .defaultProfileImage4)
   }

   @Test("すべて使用済みならデフォルトプロフィール画像に戻る")
   func profileImageFallsBackWhenEveryImageIsUsed() {
      #expect(DefaultProfileImage.firstAvailable(excluding: Set(DefaultProfileImage.allCases)) == .defaultProfileImage)
   }
}

struct AdDisplayPolicyTests {
   @Test("一覧広告は項目がある無料ユーザーだけに表示される")
   func listAdsShowOnlyForFreeUsersWithItems() {
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: true))
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: false).showsListAd(hasItems: false) == false)
   }

   @Test("一覧広告は広告非表示購入済みとプレミアムユーザーには表示されない")
   func listAdsAreHiddenForAdRemovedAndPremiumUsers() {
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: false).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: false, isPremium: true).showsListAd(hasItems: true) == false)
      #expect(AdDisplayPolicy(adsRemoved: true, isPremium: true).showsListAd(hasItems: true) == false)
   }
}

struct PremiumAccessPolicyTests {
   @Test("無料人物上限はわたしを含めて3人で止まる")
   func freePersonLimitIncludesMeAndStopsAtThreePeople() {
      #expect(PremiumAccessPolicy.freePersonLimit == 3)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 1).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 2).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 3).canAddPerson == false)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: false, personCount: 4).canAddPerson == false)
   }

   @Test("プレミアムと旧広告非表示購入はいずれも人物上限を解除する")
   func premiumAndLegacyAdRemovalBothUnlockPersonLimit() {
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: false, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: true, adsRemoved: true, personCount: 8).canAddPerson)
      #expect(PremiumAccessPolicy(isPremium: false, adsRemoved: true, personCount: 3).hasPremiumAccess)
   }
}

struct AppTextSizeTests {
   @Test("文字サイズは小さい順から大きい順に並ぶ")
   func textSizesAreOrderedFromSmallestToLargest() {
      #expect(AppTextSize.allCases == [.extraSmall, .small, .standard, .large, .extraLarge])
   }

   @Test("文字サイズタイトルは全選択肢を網羅する")
   func textSizeTitlesExistForEveryCase() {
      #expect(AppTextSize.allCases.count == 5)

      for textSize in AppTextSize.allCases {
         #expect(String(describing: textSize.title).isEmpty == false)
      }
   }

   @Test("ホームのアバターサイズはアプリ文字サイズに追従する")
   func homeAvatarSizeScalesWithTextSize() {
      let extraSmall = AppLayoutMetrics(textSize: .extraSmall).homePersonAvatarSize
      let standard = AppLayoutMetrics(textSize: .standard).homePersonAvatarSize
      let extraLarge = AppLayoutMetrics(textSize: .extraLarge).homePersonAvatarSize

      #expect(extraSmall < standard)
      #expect(standard < extraLarge)
   }

   @Test("文字サイズの段階移動は選択可能範囲で止まる")
   func textSizeAdvancementClampsAtBounds() {
      #expect(AppTextSize.extraSmall.advanced(by: 2) == .standard)
      #expect(AppTextSize.small.advanced(by: 2) == .large)
      #expect(AppTextSize.standard.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.large.advanced(by: 2) == .extraLarge)
      #expect(AppTextSize.extraSmall.advanced(by: -2) == .extraSmall)
   }

   @Test("レイアウト寸法は選択した文字サイズに合わせて広がる")
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
