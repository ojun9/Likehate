/// 好き・嫌いの登録種別。
enum EntryKind: String, CaseIterable, Identifiable, Codable {
   case like
   case hate

   var id: String { rawValue }

   /// 旧データ移行で使う保存キー。
   var storageKey: String {
      switch self {
      case .like: return "OpenLikeKey"
      case .hate: return "OpenHateKey"
      }
   }

   /// 既存分析イベントとの互換用の種別名。
   var analyticsName: String {
      switch self {
      case .like: return "RegiLike"
      case .hate: return "RegiHate"
      }
   }
}
