import SwiftUI

/// 人物フォームを追加として使うか編集として使うかを表す。
enum PersonFormMode: Identifiable {
   case add
   case edit(Person)

   var id: String {
      switch self {
      case .add:
         return "add"
      case .edit(let person):
         return person.id.uuidString
      }
   }

   var title: String {
      switch self {
      case .add:
         return String(localized: "AddPersonTitle")
      case .edit(let person):
         return String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat"), person.displayName)
      }
   }

   var saveTitle: LocalizedStringKey {
      switch self {
      case .add: return "AddPersonSaveButton"
      case .edit: return "SavePersonChangesButton"
      }
   }

   var allowsNameEditing: Bool {
      true
   }
}
