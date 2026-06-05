import Foundation

struct LikeDislikeItem: Identifiable, Codable, Hashable {
   var id: UUID
   var personId: UUID
   var type: EntryKind
   var title: String
   var note: String?
   var createdAt: Date
   var updatedAt: Date
   var sortOrder: Int
}
