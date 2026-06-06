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

extension Person {
   fileprivate enum CodingKeys: String, CodingKey {
      case id
      case name
      case profileImageName
      case photoFileName
      case isMe
      case createdAt
      case updatedAt
      case sortOrder
   }

   init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      let decodedIsMe = container.compatibleDecode(Bool.self, forKey: .isMe) ?? false
      let decodedUpdatedAt = container.compatibleDecode(Date.self, forKey: .updatedAt)
      let decodedCreatedAt = container.compatibleDecode(Date.self, forKey: .createdAt)
         ?? decodedUpdatedAt
         ?? Date(timeIntervalSince1970: 0)

      id = container.compatibleDecode(UUID.self, forKey: .id) ?? UUID()
      name = container.compatibleDecode(String.self, forKey: .name) ?? (decodedIsMe ? String(localized: "DefaultMeName") : "")
      profileImageName = container.compatibleDecode(String.self, forKey: .profileImageName)
      photoFileName = container.compatibleDecode(String.self, forKey: .photoFileName)
      isMe = decodedIsMe
      createdAt = decodedCreatedAt
      updatedAt = decodedUpdatedAt ?? decodedCreatedAt
      sortOrder = container.compatibleDecode(Int.self, forKey: .sortOrder) ?? 0
   }

   func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encodeIfPresent(profileImageName, forKey: .profileImageName)
      try container.encodeIfPresent(photoFileName, forKey: .photoFileName)
      try container.encode(isMe, forKey: .isMe)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(sortOrder, forKey: .sortOrder)
   }
}

private extension KeyedDecodingContainer where Key == Person.CodingKeys {
   func compatibleDecode<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
      try? decodeIfPresent(type, forKey: key)
   }
}
