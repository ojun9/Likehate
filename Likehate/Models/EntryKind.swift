enum EntryKind: String, CaseIterable, Identifiable, Codable {
   case like
   case hate

   var id: String { rawValue }

   var storageKey: String {
      switch self {
      case .like: return "OpenLikeKey"
      case .hate: return "OpenHateKey"
      }
   }

   var analyticsName: String {
      switch self {
      case .like: return "RegiLike"
      case .hate: return "RegiHate"
      }
   }
}
