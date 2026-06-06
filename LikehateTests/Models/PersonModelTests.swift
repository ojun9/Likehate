import Foundation
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

   @Test("人物は古いJSONに新しい項目がなくても読み込める")
   func personDecodesLegacyPayloadWithoutNewFields() throws {
      let id = UUID()
      let createdAt = Date(timeIntervalSince1970: 1_234)
      let data = try JSONEncoder().encode(LegacyPersonPayload(id: id, name: "自分", isMe: true, createdAt: createdAt))

      let person = try JSONDecoder().decode(Person.self, from: data)

      #expect(person.id == id)
      #expect(person.name == "自分")
      #expect(person.isMe)
      #expect(person.profileImageName == nil)
      #expect(person.photoFileName == nil)
      #expect(person.createdAt == createdAt)
      #expect(person.updatedAt == createdAt)
      #expect(person.sortOrder == 0)
      #expect(person.displayName == String(localized: "DefaultMeName"))
   }
}

private struct LegacyPersonPayload: Encodable {
   let id: UUID
   let name: String
   let isMe: Bool
   let createdAt: Date
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

struct DefaultProfileImageTests {
   private struct FixedRandomNumberGenerator: RandomNumberGenerator {
      var nextValue: UInt64

      mutating func next() -> UInt64 {
         nextValue
      }
   }

   @Test("デフォルトプロフィール画像は同梱アセット名と一致する")
   func profileImageAssetNamesAreStable() {
      let names = DefaultProfileImage.allCases.map(\.assetName)

      #expect(names.count == 19)
      #expect(names.first == "defaultProfileImage")
      #expect(names.last == "defaultProfileImage19")
      #expect(Set(names).count == names.count)
   }

   @Test("わたしの初期プロフィール画像は4番目の同梱画像にする")
   func initialMeProfileImageIsFourthPreset() {
      #expect(DefaultProfileImage.initialMeImage == .defaultProfileImage4)
      #expect(DefaultProfileImage.initialMeImage.assetName == "defaultProfileImage4")
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

   @Test("デフォルトプロフィール画像は未使用画像からランダムに選ぶ")
   func profileImagePicksRandomUnusedImage() {
      let usedImages: Set<DefaultProfileImage> = [
         .defaultProfileImage,
         .defaultProfileImage2,
         .defaultProfileImage3
      ]
      var firstGenerator = FixedRandomNumberGenerator(nextValue: 0)
      var secondGenerator = FixedRandomNumberGenerator(nextValue: 1)

      let firstPick = DefaultProfileImage.randomAvailable(excluding: usedImages, using: &firstGenerator)
      let secondPick = DefaultProfileImage.randomAvailable(excluding: usedImages, using: &secondGenerator)

      #expect(firstPick == .defaultProfileImage4)
      #expect(secondPick == .defaultProfileImage5)
      #expect(usedImages.contains(firstPick) == false)
      #expect(usedImages.contains(secondPick) == false)
   }

   @Test("すべて使用済みならデフォルトプロフィール画像に戻る")
   func profileImageFallsBackWhenEveryImageIsUsed() {
      #expect(DefaultProfileImage.firstAvailable(excluding: Set(DefaultProfileImage.allCases)) == .defaultProfileImage)
   }

   @Test("未使用画像がない場合だけ全画像からランダムに選ぶ")
   func profileImageRandomFallsBackToAllImagesWhenEveryImageIsUsed() {
      var generator = FixedRandomNumberGenerator(nextValue: 1)

      let image = DefaultProfileImage.randomAvailable(excluding: Set(DefaultProfileImage.allCases), using: &generator)

      #expect(image == .defaultProfileImage2)
   }
}
