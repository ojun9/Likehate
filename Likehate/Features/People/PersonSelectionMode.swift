import SwiftUI

/// 人物選択画面を追加用、閲覧用のどちらの文脈で開くかを表す。
enum PersonSelectionMode {
   case register
   case browse

   var title: LocalizedStringKey {
      switch self {
      case .register: return "ChoosePersonForEntryTitle"
      case .browse: return "ChoosePersonToBrowseTitle"
      }
   }
}
