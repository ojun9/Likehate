import SwiftUI

extension ComparisonCategory {
   /// 比較結果セルで使う控えめな背景色。
   var color: Color {
      switch self {
      case .commonLike:
         return EntryKind.like.color.opacity(0.22)
      case .firstOnlyLike, .secondOnlyLike:
         return EntryKind.like.color.opacity(0.12)
      case .commonHate:
         return EntryKind.hate.color.opacity(0.24)
      case .firstOnlyHate, .secondOnlyHate:
         return EntryKind.hate.color.opacity(0.13)
      }
   }

   /// 比較結果セルのアクセント枠色。
   var borderColor: Color {
      switch self {
      case .firstOnlyLike, .commonLike, .secondOnlyLike:
         return EntryKind.like.color.opacity(0.32)
      case .firstOnlyHate, .commonHate, .secondOnlyHate:
         return EntryKind.hate.color.opacity(0.34)
      }
   }

   /// 比較対象の表示名を反映したユーザー向けカテゴリ名。
   func title(first: Person, second: Person) -> String {
      switch self {
      case .firstOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonFirstOnlyLikeFormat"), first.displayName)
      case .commonLike:
         return String(localized: "ComparisonCommonLike")
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonSecondOnlyLikeFormat"), second.displayName)
      case .firstOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonFirstOnlyHateFormat"), first.displayName)
      case .commonHate:
         return String(localized: "ComparisonCommonHate")
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonSecondOnlyHateFormat"), second.displayName)
      }
   }
}
