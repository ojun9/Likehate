import Foundation

/// 購入・復元処理の結果として表示する一時メッセージ。
struct PurchaseMessage: Identifiable {
   let id = UUID()
   let title: String
   let message: String
}

/// レビュー依頼の確認ダイアログに表示する一時メッセージ。
struct ReviewPrompt: Identifiable {
   let id = UUID()
   let title: String
   let message: String
}
