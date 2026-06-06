/// 2人の好き嫌いを比較したときの分類。
enum ComparisonCategory: String, CaseIterable, Identifiable {
   case firstOnlyLike
   case commonLike
   case secondOnlyLike
   case firstOnlyHate
   case commonHate
   case secondOnlyHate

   var id: String { rawValue }

   /// この比較カテゴリが好き・嫌いのどちらに属するか。
   var kind: EntryKind {
      switch self {
      case .firstOnlyLike, .commonLike, .secondOnlyLike:
         return .like
      case .firstOnlyHate, .commonHate, .secondOnlyHate:
         return .hate
      }
   }
}
