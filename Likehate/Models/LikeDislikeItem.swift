import Foundation

/// 人物に紐づく好き・嫌いの1項目。
struct LikeDislikeItem: Identifiable, Codable, Hashable {
   /// 項目ID。
   var id: UUID
   /// 所有する人物ID。
   var personId: UUID
   /// 好き・嫌いの種別。
   var type: EntryKind
   /// ユーザーが入力した項目名。
   var title: String
   /// 将来拡張用のメモ欄。
   var note: String?
   /// 作成日時。
   var createdAt: Date
   /// 更新日時。
   var updatedAt: Date
   /// 人物・種別内での表示順。
   var sortOrder: Int
}
