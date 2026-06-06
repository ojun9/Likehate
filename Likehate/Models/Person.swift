import Foundation

/// 好き嫌いを記録する対象人物。
struct Person: Identifiable, Codable, Hashable {
   /// 人物ID。
   var id: UUID
   /// 保存上の人物名。`isMe`でもユーザーが変更した名前を保持する。
   var name: String
   /// プリセットプロフィール画像名。
   var profileImageName: String?
   /// アプリ内に保存した写真ファイル名。
   var photoFileName: String?
   /// 初期人物の「わたし」かどうか。
   var isMe: Bool
   /// 作成日時。
   var createdAt: Date
   /// 更新日時。
   var updatedAt: Date
   /// ホーム上の表示順。
   var sortOrder: Int

   /// UIに表示する人物名。古い「自分」保存値は「わたし」に置き換える。
   var displayName: String {
      let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
      if isMe {
         if trimmedName.isEmpty || trimmedName == "自分" {
            return String(localized: "DefaultMeName")
         }
         return trimmedName
      }

      return trimmedName.isEmpty ? name : trimmedName
   }

   /// 保存値が壊れていても必ず有効なプリセット画像を返す。
   var profileImage: DefaultProfileImage {
      get { DefaultProfileImage(rawValue: profileImageName ?? "") ?? .defaultProfileImage }
      set { profileImageName = newValue.rawValue }
   }
}
