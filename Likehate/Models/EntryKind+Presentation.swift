import SwiftUI

extension EntryKind {
   var title: String {
      switch self {
      case .like: return String(localized: "Like")
      case .hate: return String(localized: "Hate")
      }
   }

   func title(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, _):
         return String(localized: "Like")
      case (.hate, _):
         return String(localized: "Hate")
      }
   }

   var selectionSubtitle: String {
      switch self {
      case .like: return String(localized: "LikeSelectionSubtitle")
      case .hate: return String(localized: "HateSelectionSubtitle")
      }
   }

   var listTitle: String {
      switch self {
      case .like: return String(localized: "likething")
      case .hate: return String(localized: "hatething")
      }
   }

   var prompt: String {
      switch self {
      case .like: return String(localized: "WhatLike")
      case .hate: return String(localized: "WhatHate")
      }
   }

   var inputPlaceholder: String {
      switch self {
      case .like: return String(localized: "LikeInputPlaceholder")
      case .hate: return String(localized: "HateInputPlaceholder")
      }
   }

   func inputPlaceholder(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "LikeInputPlaceholder"
      case (.hate, _):
         return "HateInputPlaceholder"
      }
   }

   var inputButtonTitle: String {
      switch self {
      case .like: return String(localized: "LikeInputButton")
      case .hate: return String(localized: "HateInputButton")
      }
   }

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

   func emptyListTitle(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "EmptyLikesTitle"
      case (.hate, _):
         return "EmptyHatesTitle"
      }
   }

   func emptyListMessage(for person: Person) -> LocalizedStringKey {
      switch self {
      case .like: return "EmptyLikesMessage"
      case .hate: return "EmptyHatesMessage"
      }
   }

   var color: Color {
      switch self {
      case .like: return LikehateTheme.likeAccent
      case .hate: return LikehateTheme.hateAccent
      }
   }
}
