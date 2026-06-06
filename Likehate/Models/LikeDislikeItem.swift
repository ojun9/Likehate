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

extension LikeDislikeItem {
   fileprivate enum CodingKeys: String, CodingKey {
      case id
      case personId
      case personID
      case type
      case kind
      case title
      case note
      case createdAt
      case updatedAt
      case sortOrder
   }

   init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let decodedUpdatedAt = container.compatibleDecode(Date.self, forKey: .updatedAt)
      let decodedCreatedAt = container.compatibleDecode(Date.self, forKey: .createdAt)
         ?? decodedUpdatedAt
         ?? Date(timeIntervalSince1970: 0)

      id = container.compatibleDecode(UUID.self, forKey: .id) ?? UUID()
      personId = container.compatibleDecode(UUID.self, forKey: .personId)
         ?? container.compatibleDecode(UUID.self, forKey: .personID)
         ?? UUID()
      type = container.compatibleDecode(EntryKind.self, forKey: .type)
         ?? container.compatibleDecode(EntryKind.self, forKey: .kind)
         ?? Self.compatibleEntryKind(from: container.compatibleDecode(String.self, forKey: .type))
         ?? Self.compatibleEntryKind(from: container.compatibleDecode(String.self, forKey: .kind))
         ?? .like
      title = container.compatibleDecode(String.self, forKey: .title) ?? ""
      note = container.compatibleDecode(String.self, forKey: .note)
      createdAt = decodedCreatedAt
      updatedAt = decodedUpdatedAt ?? decodedCreatedAt
      sortOrder = container.compatibleDecode(Int.self, forKey: .sortOrder) ?? 0
   }

   func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(personId, forKey: .personId)
      try container.encode(type, forKey: .type)
      try container.encode(title, forKey: .title)
      try container.encodeIfPresent(note, forKey: .note)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(sortOrder, forKey: .sortOrder)
   }

   private static func compatibleEntryKind(from rawValue: String?) -> EntryKind? {
      switch rawValue {
      case EntryKind.like.rawValue, EntryKind.like.analyticsName, EntryKind.like.storageKey:
         return .like
      case EntryKind.hate.rawValue, EntryKind.hate.analyticsName, EntryKind.hate.storageKey:
         return .hate
      default:
         return nil
      }
   }
}

private extension KeyedDecodingContainer where Key == LikeDislikeItem.CodingKeys {
   func compatibleDecode<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
      try? decodeIfPresent(type, forKey: key)
   }
}
