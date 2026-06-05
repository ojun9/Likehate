enum EntryPreviewItems {
   static let maxCount = 2

   static func items(from items: [LikeDislikeItem], limit: Int = maxCount) -> [LikeDislikeItem] {
      guard limit > 0 else { return [] }
      return Array(items.prefix(limit))
   }
}

enum EntryLottieSelection {
   static let likeNames = ["MoreHarts", "heart1", "heart2"]
   static let hateNames = ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"]

   static func names(for kind: EntryKind) -> [String] {
      switch kind {
      case .like: return likeNames
      case .hate: return hateNames
      }
   }

   static func randomName(for kind: EntryKind, excluding currentName: String? = nil) -> String {
      let names = names(for: kind)
      let candidates = names.filter { $0 != currentName }
      return (candidates.isEmpty ? names : candidates).randomElement() ?? fallbackName(for: kind)
   }

   static func fallbackName(for kind: EntryKind) -> String {
      names(for: kind).first ?? ""
   }
}
