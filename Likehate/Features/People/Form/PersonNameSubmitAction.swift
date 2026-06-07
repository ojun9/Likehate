/// 名前入力のReturnキーで実行する動作。
enum PersonNameSubmitAction {
   enum Action: Equatable {
      case dismissKeyboard
   }

   case done

   func action() -> Action {
      switch self {
      case .done:
         return .dismissKeyboard
      }
   }
}
