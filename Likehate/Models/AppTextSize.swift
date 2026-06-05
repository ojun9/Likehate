import SwiftUI

enum AppTextSize: String, CaseIterable, Codable, Hashable, Identifiable {
   case extraSmall
   case small
   case standard
   case large
   case extraLarge

   var id: String { rawValue }

   func advanced(by offset: Int) -> AppTextSize {
      let allSizes = Self.allCases
      guard let currentIndex = allSizes.firstIndex(of: self) else { return self }
      let clampedIndex = min(max(currentIndex + offset, 0), allSizes.count - 1)
      return allSizes[clampedIndex]
   }

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
