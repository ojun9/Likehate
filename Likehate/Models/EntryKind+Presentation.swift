import SwiftUI

extension EntryKind {
   /// 種別単体の表示名。
   var title: String {
      switch self {
      case .like: return String(localized: "Like")
      case .hate: return String(localized: "Hate")
      }
   }

   /// 人物文脈で使う種別名。
   func title(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, _):
         return String(localized: "Like")
      case (.hate, _):
         return String(localized: "Hate")
      }
   }

   /// 種別選択画面に表示する補足文。
   var selectionSubtitle: String {
      switch self {
      case .like: return String(localized: "LikeSelectionSubtitle")
      case .hate: return String(localized: "HateSelectionSubtitle")
      }
   }

   /// 旧一覧画面向けのタイトル。
   var listTitle: String {
      switch self {
      case .like: return String(localized: "likething")
      case .hate: return String(localized: "hatething")
      }
   }

   /// 入力画面の問いかけ文。
   var prompt: String {
      switch self {
      case .like: return String(localized: "WhatLike")
      case .hate: return String(localized: "WhatHate")
      }
   }

   /// 入力欄のプレースホルダー文言。
   var inputPlaceholder: String {
      switch self {
      case .like: return String(localized: "LikeInputPlaceholder")
      case .hate: return String(localized: "HateInputPlaceholder")
      }
   }

   /// 人物ごとの入力欄プレースホルダー文言。
   func inputPlaceholder(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "LikeInputPlaceholder"
      case (.hate, _):
         return "HateInputPlaceholder"
      }
   }

   /// 入力画面の保存ボタン文言。
   var inputButtonTitle: String {
      switch self {
      case .like: return String(localized: "LikeInputButton")
      case .hate: return String(localized: "HateInputButton")
      }
   }

   /// 人物ごとの入力画面保存ボタン文言。
   func inputButtonTitle(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, true):
         return String(localized: "LikeInputButtonMe")
      case (.like, false):
         return String.localizedStringWithFormat(String(localized: "LikeInputButtonPersonFormat"), person.displayName)
      case (.hate, true):
         return String(localized: "HateInputButtonMe")
      case (.hate, false):
         return String.localizedStringWithFormat(String(localized: "HateInputButtonPersonFormat"), person.displayName)
      }
   }

   /// 好き・嫌い一覧画面のタイトル。
   func listTitle(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, true):
         return String(localized: "MyLikesTitle")
      case (.like, false):
         return String.localizedStringWithFormat(String(localized: "PersonLikesTitleFormat"), person.displayName)
      case (.hate, true):
         return String(localized: "MyHatesTitle")
      case (.hate, false):
         return String.localizedStringWithFormat(String(localized: "PersonHatesTitleFormat"), person.displayName)
      }
   }

   /// 一覧が空のときのメイン文言キー。
   func emptyListTitle(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "EmptyLikesTitle"
      case (.hate, _):
         return "EmptyHatesTitle"
      }
   }

   /// 一覧が空のときの補足文キー。
   func emptyListMessage(for person: Person) -> LocalizedStringKey {
      switch self {
      case .like: return "EmptyLikesMessage"
      case .hate: return "EmptyHatesMessage"
      }
   }

   /// 種別ごとのアクセント色。
   var color: Color {
      switch self {
      case .like: return LikehateTheme.likeAccent
      case .hate: return LikehateTheme.hateAccent
      }
   }
}
