import SwiftUI

enum LikehateTheme {
   static let background = dynamicColor(
      light: UIColor(red: 0.984, green: 0.976, blue: 0.992, alpha: 1),
      dark: UIColor(red: 0.071, green: 0.071, blue: 0.094, alpha: 1)
   )

   static let surface = dynamicColor(
      light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
      dark: UIColor(red: 0.114, green: 0.118, blue: 0.145, alpha: 1)
   )

   static let elevatedSurface = dynamicColor(
      light: UIColor(red: 1, green: 0.988, blue: 0.996, alpha: 1),
      dark: UIColor(red: 0.133, green: 0.137, blue: 0.169, alpha: 1)
   )

   static let inputSurface = dynamicColor(
      light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
      dark: UIColor(red: 0.102, green: 0.106, blue: 0.129, alpha: 1)
   )

   static let border = dynamicColor(
      light: UIColor(red: 0.16, green: 0.13, blue: 0.19, alpha: 0.08),
      dark: UIColor(white: 1, alpha: 0.09)
   )

   static let separator = dynamicColor(
      light: UIColor(red: 0.16, green: 0.13, blue: 0.19, alpha: 0.08),
      dark: UIColor(white: 1, alpha: 0.08)
   )

   static let likeAccent = Color(red: 1.0, green: 0.365, blue: 0.478)
   static let hateAccent = Color(red: 0.337, green: 0.522, blue: 0.929)
   static let sparkleAccent = Color(red: 0.839, green: 0.698, blue: 0.298)

   static func accent(for kind: EntryKind) -> Color {
      switch kind {
      case .like: return likeAccent
      case .hate: return hateAccent
      }
   }

   static func cardShadow(for scheme: ColorScheme) -> Color {
      scheme == .dark ? .black.opacity(0.2) : .black.opacity(0.055)
   }

   static func tintFill(_ color: Color, scheme: ColorScheme) -> Color {
      color.opacity(scheme == .dark ? 0.12 : 0.075)
   }

   private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
      Color(UIColor { traits in
         traits.userInterfaceStyle == .dark ? dark : light
      })
   }
}

struct AppTypography {
   let textSize: AppTextSize
   let dynamicTypeSize: DynamicTypeSize

   var screenTitle: Font { font(.screenTitle, weight: .bold, design: .default) }
   var sectionTitle: Font { font(.sectionTitle, weight: .bold, design: .rounded) }
   var cardTitle: Font { font(.cardTitle, weight: .bold, design: .rounded) }
   var body: Font { font(.body, weight: .medium, design: .rounded) }
   var bodyRegular: Font { font(.body, weight: .regular, design: .rounded) }
   var prominentListBody: Font { font(.body, textSize: textSize.advanced(by: 2), weight: .medium, design: .rounded) }
   var subtext: Font { font(.subtext, weight: .medium, design: .rounded) }
   var button: Font { font(.button, weight: .bold, design: .rounded) }
   var count: Font { font(.count, weight: .semibold, design: .rounded) }

   private func font(_ token: FontToken, textSize resolvedTextSize: AppTextSize? = nil, weight: Font.Weight, design: Font.Design) -> Font {
      .system(size: scaledSize(for: token, textSize: resolvedTextSize ?? textSize), weight: weight, design: design)
   }

   private func scaledSize(for token: FontToken, textSize resolvedTextSize: AppTextSize) -> CGFloat {
      token.baseSize(for: resolvedTextSize) * dynamicTypeScale
   }

   private var dynamicTypeScale: CGFloat {
      switch dynamicTypeSize {
      case .xSmall: return 0.92
      case .small: return 0.96
      case .medium: return 0.98
      case .large: return 1.0
      case .xLarge: return 1.08
      case .xxLarge: return 1.16
      case .xxxLarge: return 1.25
      case .accessibility1: return 1.36
      case .accessibility2: return 1.48
      case .accessibility3: return 1.62
      case .accessibility4: return 1.78
      case .accessibility5: return 1.96
      @unknown default: return 1.0
      }
   }
}

private enum FontToken {
   case screenTitle
   case sectionTitle
   case cardTitle
   case body
   case subtext
   case button
   case count

   func baseSize(for textSize: AppTextSize) -> CGFloat {
      switch (self, textSize) {
      case (.screenTitle, .extraSmall): return 20
      case (.screenTitle, .small): return 22
      case (.screenTitle, .standard): return 24
      case (.screenTitle, .large): return 26
      case (.screenTitle, .extraLarge): return 28
      case (.sectionTitle, .extraSmall): return 22
      case (.sectionTitle, .small): return 24
      case (.sectionTitle, .standard): return 28
      case (.sectionTitle, .large): return 31
      case (.sectionTitle, .extraLarge): return 34
      case (.cardTitle, .extraSmall): return 17
      case (.cardTitle, .small): return 18
      case (.cardTitle, .standard): return 20
      case (.cardTitle, .large): return 22
      case (.cardTitle, .extraLarge): return 24
      case (.body, .extraSmall): return 16
      case (.body, .small): return 17
      case (.body, .standard): return 19
      case (.body, .large): return 21
      case (.body, .extraLarge): return 23
      case (.subtext, .extraSmall): return 13
      case (.subtext, .small): return 14
      case (.subtext, .standard): return 16
      case (.subtext, .large): return 17
      case (.subtext, .extraLarge): return 19
      case (.button, .extraSmall): return 16
      case (.button, .small): return 17
      case (.button, .standard): return 18
      case (.button, .large): return 20
      case (.button, .extraLarge): return 22
      case (.count, .extraSmall): return 16
      case (.count, .small): return 18
      case (.count, .standard): return 20
      case (.count, .large): return 22
      case (.count, .extraLarge): return 24
      }
   }
}

struct AppLayoutMetrics {
   let textSize: AppTextSize

   var screenPadding: CGFloat {
      switch textSize {
      case .extraSmall: return 16
      case .small: return 18
      case .standard: return 20
      case .large: return 22
      case .extraLarge: return 22
      }
   }

   var cardPadding: CGFloat {
      switch textSize {
      case .extraSmall: return 14
      case .small: return 16
      case .standard: return 18
      case .large: return 20
      case .extraLarge: return 22
      }
   }

   var cardSpacing: CGFloat {
      switch textSize {
      case .extraSmall: return 10
      case .small: return 12
      case .standard: return 14
      case .large: return 16
      case .extraLarge: return 18
      }
   }

   var sectionSpacing: CGFloat {
      switch textSize {
      case .extraSmall: return 20
      case .small: return 22
      case .standard: return 26
      case .large: return 30
      case .extraLarge: return 34
      }
   }

   var rowMinHeight: CGFloat {
      switch textSize {
      case .extraSmall: return 48
      case .small: return 52
      case .standard: return 58
      case .large: return 64
      case .extraLarge: return 70
      }
   }

   var personCardMinHeight: CGFloat {
      switch textSize {
      case .extraSmall: return 104
      case .small: return 112
      case .standard: return 124
      case .large: return 136
      case .extraLarge: return 148
      }
   }

   var homePersonAvatarSize: CGFloat {
      switch textSize {
      case .extraSmall: return 78
      case .small: return 84
      case .standard: return 93
      case .large: return 102
      case .extraLarge: return 111
      }
   }
}
