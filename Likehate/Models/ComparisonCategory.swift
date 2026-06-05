enum ComparisonCategory: String, CaseIterable, Identifiable {
   case firstOnlyLike
   case commonLike
   case secondOnlyLike
   case firstOnlyHate
   case commonHate
   case secondOnlyHate

   var id: String { rawValue }

   var kind: EntryKind {
      switch self {
      case .firstOnlyLike, .commonLike, .secondOnlyLike:
         return .like
      case .firstOnlyHate, .commonHate, .secondOnlyHate:
         return .hate
      }
   }
}
