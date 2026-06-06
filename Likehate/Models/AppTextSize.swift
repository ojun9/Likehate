import SwiftUI

/// アプリ内で独自に選べる文字サイズ。
enum AppTextSize: String, CaseIterable, Codable, Hashable, Identifiable {
   case extraSmall
   case small
   case standard
   case large
   case extraLarge

   var id: String { rawValue }

   /// 現在値から指定段階だけ進めた文字サイズを、範囲内に丸めて返す。
   func advanced(by offset: Int) -> AppTextSize {
      let allSizes = Self.allCases
      guard let currentIndex = allSizes.firstIndex(of: self) else { return self }
      let clampedIndex = min(max(currentIndex + offset, 0), allSizes.count - 1)
      return allSizes[clampedIndex]
   }

   /// 設定画面に表示するローカライズ済みタイトルキー。
   var title: LocalizedStringKey {
      switch self {
      case .extraSmall: return "TextSizeExtraSmall"
      case .small: return "TextSizeSmall"
      case .standard: return "TextSizeStandard"
      case .large: return "TextSizeLarge"
      case .extraLarge: return "TextSizeExtraLarge"
      }
   }
}
