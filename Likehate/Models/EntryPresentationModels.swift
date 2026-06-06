/// 人物詳細に表示する好き・嫌いプレビュー項目の選択ルール。
enum EntryPreviewItems {
   /// 人物詳細に最大表示する項目数。
   static let maxCount = 2

   /// 既に並び替え済みの項目から、先頭のプレビュー分だけ返す。
   static func items(from items: [LikeDislikeItem], limit: Int = maxCount) -> [LikeDislikeItem] {
      guard limit > 0 else { return [] }
      return Array(items.prefix(limit))
   }
}

/// 好き・嫌い入力画面に表示するLottieの選択ルール。
enum EntryLottieSelection {
   /// 好き入力で使うLottie名。
   static let likeNames = ["MoreHarts", "heart1", "heart2"]
   /// 嫌い入力で使うLottie名。
   static let hateNames = ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"]

   /// 種別に対応するLottie候補を返す。
   static func names(for kind: EntryKind) -> [String] {
      switch kind {
      case .like: return likeNames
      case .hate: return hateNames
      }
   }

   /// 可能なら直前と違うLottie名をランダムに返す。
   static func randomName(for kind: EntryKind, excluding currentName: String? = nil) -> String {
      let names = names(for: kind)
      let candidates = names.filter { $0 != currentName }
      return (candidates.isEmpty ? names : candidates).randomElement() ?? fallbackName(for: kind)
   }

   /// 候補が空だった場合のフォールバック名。
   static func fallbackName(for kind: EntryKind) -> String {
      names(for: kind).first ?? ""
   }
}
