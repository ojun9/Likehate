import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct SlideSpec {
   let key: String
   let headline: [String: String]
   let gradientStart: NSColor
   let gradientEnd: NSColor
   let vividStart: NSColor
   let vividEnd: NSColor
   let accent: NSColor
   let secondaryAccent: NSColor
}

struct VariantSpec {
   let folderName: String
   let titleTop: CGFloat
   let titleLeft: CGFloat
   let japaneseFontSize: CGFloat
   let englishFontSize: CGFloat
   let titleWidth: CGFloat
   let phoneWidths: [CGFloat]
   let phoneCenterX: [CGFloat]
   let phoneBottom: [CGFloat]
   let phoneRotations: [CGFloat]
   let artStyle: ArtStyle
   let usesVividBackground: Bool
   let headlineColor: NSColor
   let headlineShadow: Bool
}

enum ArtStyle {
   case bloom
   case diagonal
   case halo
   case ribbon
   case bubble
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let canvasSize = NSSize(width: 1290, height: 2796)
let exampleLocales = ["ja", "en"]
let sourceLocales = ["ja", "en"]
let sourceDirectory = root.appendingPathComponent("public/screenshots/iphone")
let outputRoot = root.appendingPathComponent("screenshots/example")
let finalOutputRoot = root.appendingPathComponent("screenshots/app-store/iphone-6.9")
let fastlaneScreenshotsRoot = root.appendingPathComponent("fastlane/screenshots")
let selectedVariantFolderName = "proposal-04-playful-tilt"
let datePattern = #"(\d{4}-\d{2}-\d{2}) at (\d{2})\.(\d{2})\.(\d{2})"#
let dateRegex = try NSRegularExpression(pattern: datePattern)

let slides: [SlideSpec] = [
   SlideSpec(
      key: "home",
      headline: [
         "ja": "好きも苦手も\n忘れない。",
         "en": "Remember\nlikes and dislikes"
      ],
      gradientStart: color("#FFF1F5"),
      gradientEnd: color("#F4ECFF"),
      vividStart: color("#FF4F8B"),
      vividEnd: color("#7C3AED"),
      accent: color("#FF7EA8"),
      secondaryAccent: color("#BFA2FF")
   ),
   SlideSpec(
      key: "person",
      headline: [
         "ja": "人ごとに\nちゃんと残せる。",
         "en": "Keep tastes\nfor each person"
      ],
      gradientStart: color("#FFF6EA"),
      gradientEnd: color("#FFF0F4"),
      vividStart: color("#F97316"),
      vividEnd: color("#DB2777"),
      accent: color("#FF9C7A"),
      secondaryAccent: color("#FF8FB7")
   ),
   SlideSpec(
      key: "compare",
      headline: [
         "ja": "ふたりの違いが\n見える。",
         "en": "See the\ndifferences"
      ],
      gradientStart: color("#EEF8FF"),
      gradientEnd: color("#F4EEFF"),
      vividStart: color("#2EEBFF"),
      vividEnd: color("#0078FF"),
      accent: color("#80C7FF"),
      secondaryAccent: color("#E99AD6")
   ),
   SlideSpec(
      key: "both-like",
      headline: [
         "ja": "一緒に楽しめるものが\n見つかる。",
         "en": "Find what\nyou both like"
      ],
      gradientStart: color("#FFF3E8"),
      gradientEnd: color("#FFF1F7"),
      vividStart: color("#FF8A00"),
      vividEnd: color("#FF2E4F"),
      accent: color("#FFB36B"),
      secondaryAccent: color("#FF87AF")
   ),
   SlideSpec(
      key: "edit-person",
      headline: [
         "ja": "写真もアイコンも\n自分らしく。",
         "en": "Choose photos\nand icons"
      ],
      gradientStart: color("#EFFBF7"),
      gradientEnd: color("#F3EEFF"),
      vividStart: color("#00B894"),
      vividEnd: color("#19B5FF"),
      accent: color("#73D9C7"),
      secondaryAccent: color("#BCA4FF")
   )
]

let variants: [VariantSpec] = [
   VariantSpec(
      folderName: "proposal-01-soft-pop",
      titleTop: 185,
      titleLeft: 92,
      japaneseFontSize: 106,
      englishFontSize: 98,
      titleWidth: 1050,
      phoneWidths: [960, 930, 940, 930, 940],
      phoneCenterX: [875, 760, 745, 735, 875],
      phoneBottom: [-90, -65, -40, -135, -90],
      phoneRotations: [5, -5, 2, -3, 5],
      artStyle: .bloom,
      usesVividBackground: false,
      headlineColor: color("#1A1A1A"),
      headlineShadow: false
   ),
   VariantSpec(
      folderName: "proposal-02-edge-crop",
      titleTop: 145,
      titleLeft: 86,
      japaneseFontSize: 126,
      englishFontSize: 116,
      titleWidth: 1120,
      phoneWidths: [1000, 940, 960, 930, 940],
      phoneCenterX: [915, 705, 780, 725, 905],
      phoneBottom: [-230, -160, -130, -215, -150],
      phoneRotations: [7, -7, 3, -5, 6],
      artStyle: .diagonal,
      usesVividBackground: true,
      headlineColor: .white,
      headlineShadow: true
   ),
   VariantSpec(
      folderName: "proposal-03-center-glow",
      titleTop: 150,
      titleLeft: 104,
      japaneseFontSize: 118,
      englishFontSize: 108,
      titleWidth: 1040,
      phoneWidths: [940, 940, 950, 940, 940],
      phoneCenterX: [820, 735, 735, 730, 815],
      phoneBottom: [-35, -60, -45, -145, -65],
      phoneRotations: [2, -2, 0, -2, 2],
      artStyle: .halo,
      usesVividBackground: true,
      headlineColor: .white,
      headlineShadow: true
   ),
   VariantSpec(
      folderName: "proposal-04-playful-tilt",
      titleTop: 88,
      titleLeft: 72,
      japaneseFontSize: 215,
      englishFontSize: 205,
      titleWidth: 1210,
      phoneWidths: [1100, 1070, 1080, 1060, 1070],
      phoneCenterX: [900, 645, 645, 645, 645],
      phoneBottom: [-560, -520, -530, -720, -540],
      phoneRotations: [8, 0, 0, 0, 0],
      artStyle: .ribbon,
      usesVividBackground: true,
      headlineColor: .white,
      headlineShadow: true
   ),
   VariantSpec(
      folderName: "proposal-05-cute-bubbles",
      titleTop: 150,
      titleLeft: 100,
      japaneseFontSize: 118,
      englishFontSize: 110,
      titleWidth: 1040,
      phoneWidths: [950, 940, 940, 930, 940],
      phoneCenterX: [830, 735, 735, 725, 830],
      phoneBottom: [-70, -60, -50, -135, -75],
      phoneRotations: [4, -4, 1, -3, 4],
      artStyle: .bubble,
      usesVividBackground: true,
      headlineColor: .white,
      headlineShadow: true
   )
]

let fastlaneLocales = try existingFastlaneScreenshotLocales()
let finalLocales = uniqueLocales(exampleLocales + fastlaneLocales)

try FileManager.default.createDirectory(at: outputRoot, withIntermediateDirectories: true)

let inputFilesByLocale = try Dictionary(uniqueKeysWithValues: sourceLocales.map { locale in
   let files = try sortedScreenshotFiles(in: sourceDirectory.appendingPathComponent(locale))
   guard files.count >= slides.count else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 1, userInfo: [
         NSLocalizedDescriptionKey: "\(sourceDirectory.appendingPathComponent(locale).path) has \(files.count) screenshots, expected at least \(slides.count)."
      ])
   }

   return (locale, Array(files.prefix(slides.count)))
})

for variant in variants {
   let variantDirectory = outputRoot.appendingPathComponent(variant.folderName)
   try FileManager.default.createDirectory(at: variantDirectory, withIntermediateDirectories: true)

   for locale in exampleLocales {
      guard let inputFiles = inputFilesByLocale[locale] else {
         continue
      }

      for (index, slide) in slides.enumerated() {
         let image = try render(
            screenshotURL: inputFiles[index],
            slide: slide,
            slideIndex: index,
            locale: locale,
            variant: variant
         )

         let outputName = String(format: "%@_%02d.png", locale, index + 1)
         let outputURL = variantDirectory.appendingPathComponent(outputName)
         try savePNG(image, to: outputURL)

         print("\(variant.folderName)/\(outputName)")
      }
   }
}

guard let selectedVariant = variants.first(where: { $0.folderName == selectedVariantFolderName }) else {
   throw NSError(domain: "GenerateAppStoreScreenshots", code: 9, userInfo: [
      NSLocalizedDescriptionKey: "Selected variant \(selectedVariantFolderName) was not found."
   ])
}

try cleanFastlaneScreenshotDirectories(for: finalLocales)

for locale in finalLocales {
   let sourceLocale = sourceLocale(for: locale)
   guard let inputFiles = inputFilesByLocale[sourceLocale] else {
      continue
   }

   for (index, slide) in slides.enumerated() {
      let image = try render(
         screenshotURL: inputFiles[index],
         slide: slide,
         slideIndex: index,
         locale: locale,
         variant: selectedVariant
      )

      try saveFinalScreenshot(image, locale: locale, slideIndex: index)
   }
}

func saveFinalScreenshot(_ image: NSImage, locale: String, slideIndex: Int) throws {
   let finalLocaleDirectory = finalOutputRoot.appendingPathComponent(locale)
   try FileManager.default.createDirectory(at: finalLocaleDirectory, withIntermediateDirectories: true)

   let finalOutputURL = finalLocaleDirectory.appendingPathComponent(String(format: "%02d.png", slideIndex + 1))
   try savePNG(image, to: finalOutputURL)

   guard let fastlaneLocale = fastlaneLocale(for: locale) else {
      return
   }

   let fastlaneDirectory = root.appendingPathComponent("fastlane/screenshots").appendingPathComponent(fastlaneLocale)
   try FileManager.default.createDirectory(at: fastlaneDirectory, withIntermediateDirectories: true)

   let fastlaneOutputURL = fastlaneDirectory.appendingPathComponent("\(slideIndex)_APP_IPHONE_67_\(slideIndex).png")
   try savePNG(image, to: fastlaneOutputURL)
}

func fastlaneLocale(for locale: String) -> String? {
   if locale == "en" {
      return "en-US"
   }

   let directory = fastlaneScreenshotsRoot.appendingPathComponent(locale)
   return FileManager.default.fileExists(atPath: directory.path) ? locale : nil
}

func cleanFastlaneScreenshotDirectories(for locales: [String]) throws {
   for locale in locales {
      guard let fastlaneLocale = fastlaneLocale(for: locale) else {
         continue
      }

      let fastlaneDirectory = fastlaneScreenshotsRoot.appendingPathComponent(fastlaneLocale)
      guard FileManager.default.fileExists(atPath: fastlaneDirectory.path) else {
         continue
      }

      let existingFiles = try FileManager.default.contentsOfDirectory(at: fastlaneDirectory, includingPropertiesForKeys: [.isRegularFileKey])
      for file in existingFiles where file.pathExtension.lowercased() == "png" {
         try FileManager.default.removeItem(at: file)
      }
   }
}

func existingFastlaneScreenshotLocales() throws -> [String] {
   guard FileManager.default.fileExists(atPath: fastlaneScreenshotsRoot.path) else {
      return []
   }

   return try FileManager.default.contentsOfDirectory(at: fastlaneScreenshotsRoot, includingPropertiesForKeys: [.isDirectoryKey])
      .filter { url in
         (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
      }
      .map(\.lastPathComponent)
      .sorted()
}

func uniqueLocales(_ locales: [String]) -> [String] {
   var seen = Set<String>()
   var result: [String] = []

   for locale in locales where !seen.contains(locale) {
      seen.insert(locale)
      result.append(locale)
   }

   return result
}

func sourceLocale(for locale: String) -> String {
   locale == "ja" ? "ja" : "en"
}

func sortedScreenshotFiles(in directory: URL) throws -> [URL] {
   let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      .filter { $0.pathExtension.lowercased() == "png" }

   return files.sorted { lhs, rhs in
      let lhsKey = timestampKey(from: lhs.lastPathComponent) ?? lhs.lastPathComponent
      let rhsKey = timestampKey(from: rhs.lastPathComponent) ?? rhs.lastPathComponent
      return lhsKey < rhsKey
   }
}

func timestampKey(from filename: String) -> String? {
   let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
   guard let match = dateRegex.firstMatch(in: filename, range: range),
         match.numberOfRanges == 5,
         let dateRange = Range(match.range(at: 1), in: filename),
         let hourRange = Range(match.range(at: 2), in: filename),
         let minuteRange = Range(match.range(at: 3), in: filename),
         let secondRange = Range(match.range(at: 4), in: filename) else {
      return nil
   }

   return "\(filename[dateRange]) \(filename[hourRange]):\(filename[minuteRange]):\(filename[secondRange])"
}

func render(
   screenshotURL: URL,
   slide: SlideSpec,
   slideIndex: Int,
   locale: String,
   variant: VariantSpec
) throws -> NSImage {
   let screenshot = try loadBitmapImage(from: screenshotURL)
   guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(canvasSize.width),
      pixelsHigh: Int(canvasSize.height),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bitmapFormat: [],
      bytesPerRow: 0,
      bitsPerPixel: 0
   ) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 4, userInfo: [
         NSLocalizedDescriptionKey: "Could not create output bitmap."
      ])
   }

   bitmap.size = canvasSize
   guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 5, userInfo: [
         NSLocalizedDescriptionKey: "Could not create graphics context."
      ])
   }

   NSGraphicsContext.saveGraphicsState()
   NSGraphicsContext.current = graphicsContext
   defer {
      graphicsContext.flushGraphics()
      NSGraphicsContext.restoreGraphicsState()
   }

   NSGraphicsContext.current?.imageInterpolation = .high
   drawBackground(size: canvasSize, slide: slide, slideIndex: slideIndex, variant: variant)
   drawPhone(screenshot, size: canvasSize, slide: slide, slideIndex: slideIndex, locale: locale, variant: variant)
   drawHeadline(size: canvasSize, slide: slide, locale: locale, variant: variant)

   let image = NSImage(size: canvasSize)
   image.addRepresentation(bitmap)
   return image
}

func loadBitmapImage(from url: URL) throws -> NSImage {
   let data = try Data(contentsOf: url)
   guard let bitmap = NSBitmapImageRep(data: data) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 2, userInfo: [
         NSLocalizedDescriptionKey: "Could not read \(url.path)"
      ])
   }

   let image = NSImage(size: NSSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh))
   image.addRepresentation(bitmap)
   return image
}

func drawBackground(size: NSSize, slide: SlideSpec, slideIndex: Int, variant: VariantSpec) {
   let bounds = NSRect(origin: .zero, size: size)
   let gradientStart = variant.usesVividBackground ? slide.vividStart : slide.gradientStart
   let gradientEnd = variant.usesVividBackground ? slide.vividEnd : slide.gradientEnd
   let accent = variant.usesVividBackground ? NSColor.white : slide.accent
   let secondaryAccent = variant.usesVividBackground ? NSColor.white : slide.secondaryAccent
   NSGradient(starting: gradientStart, ending: gradientEnd)?.draw(in: bounds, angle: 90)

   switch variant.artStyle {
   case .bloom:
      drawSoftCircle(center: point(size, 0.18, 0.76), radius: size.width * 0.44, color: accent, alpha: slideIndex == 0 ? 0.34 : 0.24)
      drawSoftCircle(center: point(size, 0.88, 0.40), radius: size.width * 0.50, color: secondaryAccent, alpha: 0.22)
      drawSoftCircle(center: point(size, 0.68, 0.08), radius: size.width * 0.24, color: .white, alpha: 0.34)
      drawSparkles(size: size, color: secondaryAccent, points: [
         point(size, 0.80, 0.82),
         point(size, 0.14, 0.56),
         point(size, 0.90, 0.25)
      ])
   case .diagonal:
      drawAngledBand(size: size, yRatio: 0.35, height: size.height * 0.28, color: accent.withAlphaComponent(0.22), angle: -10)
      drawAngledBand(size: size, yRatio: 0.05, height: size.height * 0.22, color: secondaryAccent.withAlphaComponent(0.18), angle: -10)
      drawSoftCircle(center: point(size, 0.94, 0.76), radius: size.width * 0.50, color: secondaryAccent, alpha: 0.24)
      drawSparkles(size: size, color: accent, points: [
         point(size, 0.16, 0.50),
         point(size, 0.88, 0.88)
      ])
   case .halo:
      drawSoftCircle(center: point(size, 0.50, 0.38), radius: size.width * 0.64, color: .white, alpha: 0.44)
      drawSoftCircle(center: point(size, 0.18, 0.78), radius: size.width * 0.32, color: accent, alpha: 0.20)
      drawSoftCircle(center: point(size, 0.88, 0.74), radius: size.width * 0.28, color: secondaryAccent, alpha: 0.18)
      drawRing(center: point(size, 0.13, 0.31), radius: size.width * 0.09, color: accent.withAlphaComponent(0.25), lineWidth: 8)
      drawSparkles(size: size, color: secondaryAccent, points: [
         point(size, 0.78, 0.55),
         point(size, 0.13, 0.63)
      ])
   case .ribbon:
      drawSoftCircle(center: point(size, 0.08, 0.86), radius: size.width * 0.38, color: accent, alpha: 0.30)
      drawSoftCircle(center: point(size, 0.92, 0.18), radius: size.width * 0.54, color: secondaryAccent, alpha: 0.22)
      drawWave(size: size, color: accent.withAlphaComponent(0.24), yRatio: 0.58, slideIndex: slideIndex)
      drawWave(size: size, color: .white.withAlphaComponent(0.34), yRatio: 0.47, slideIndex: slideIndex + 2)
      drawSparkles(size: size, color: secondaryAccent, points: [
         point(size, 0.84, 0.80),
         point(size, 0.18, 0.50),
         point(size, 0.78, 0.28)
      ])
   case .bubble:
      drawSoftCircle(center: point(size, 0.22, 0.78), radius: size.width * 0.36, color: accent, alpha: 0.24)
      drawSoftCircle(center: point(size, 0.86, 0.45), radius: size.width * 0.50, color: secondaryAccent, alpha: 0.20)
      drawBubbles(size: size, color: accent, secondaryColor: secondaryAccent, slideIndex: slideIndex)
      drawHearts(size: size, color: secondaryAccent.withAlphaComponent(0.24), slideIndex: slideIndex)
   }
}

func drawHeadline(size: NSSize, slide: SlideSpec, locale: String, variant: VariantSpec) {
   let paragraph = NSMutableParagraphStyle()
   paragraph.alignment = .left
   paragraph.lineBreakMode = .byWordWrapping
   paragraph.lineSpacing = variant.usesVividBackground ? -10 : (locale == "ja" ? 7 : 6)

   let fontSize = locale == "ja" ? variant.japaneseFontSize : variant.englishFontSize
   var attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: fontSize, weight: .black),
      .foregroundColor: variant.headlineColor,
      .paragraphStyle: paragraph,
      .kern: 0
   ]

   if variant.headlineShadow {
      let shadow = NSShadow()
      shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
      shadow.shadowBlurRadius = 24
      shadow.shadowOffset = NSSize(width: 0, height: -6)
      attributes[.shadow] = shadow
   }

   let headline = displayHeadline(for: slide, locale: locale, variant: variant)
   let headlineHeight: CGFloat = variant.folderName == "proposal-04-playful-tilt" ? 1000 : 500
   let rect = NSRect(
      x: variant.titleLeft,
      y: size.height - variant.titleTop - headlineHeight + 30,
      width: variant.titleWidth,
      height: headlineHeight
   )

   NSAttributedString(string: headline, attributes: attributes).draw(
      with: rect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
   )
}

func displayHeadline(for slide: SlideSpec, locale: String, variant: VariantSpec) -> String {
   guard variant.folderName == "proposal-04-playful-tilt", locale == "ja" else {
      return headlineForLocale(slide: slide, locale: locale)
   }

   switch slide.key {
   case "home":
      return "好きも\n苦手も\n忘れない。"
   case "person":
      return "人ごとに\nちゃんと\n残せる。"
   case "compare":
      return "ふたりの\n違いが\n見える。"
   case "both-like":
      return "一緒に\n楽しめる\nものが\n見つかる。"
   case "edit-person":
      return "写真も\nアイコンも\n自分らしく。"
   default:
      return headlineForLocale(slide: slide, locale: locale)
   }
}

func headlineForLocale(slide: SlideSpec, locale: String) -> String {
   let english = slide.headline["en"] ?? ""
   let candidate = localizedHeadlineCandidate(slideKey: slide.key, locale: locale) ?? english
   let normalized = normalizedLocale(locale)

   guard normalized != "en", normalized != "ja" else {
      return candidate
   }

   return comparableHeadlineLength(candidate) <= comparableHeadlineLength(english) ? candidate : english
}

func localizedHeadlineCandidate(slideKey: String, locale: String) -> String? {
   let language = normalizedLocale(locale)

   let localized: [String: [String: String]] = [
      "ja": [
         "home": "好きも苦手も\n忘れない。",
         "person": "人ごとに\nちゃんと残せる。",
         "compare": "ふたりの違いが\n見える。",
         "both-like": "一緒に楽しめるものが\n見つかる。",
         "edit-person": "写真もアイコンも\n自分らしく。"
      ],
      "en": [
         "home": "Remember\nlikes and dislikes",
         "person": "Keep tastes\nfor each person",
         "compare": "See the\ndifferences",
         "both-like": "Find what\nyou both like",
         "edit-person": "Choose photos\nand icons"
      ],
      "de": [
         "home": "Vorlieben\nmerken",
         "person": "Pro Person\nspeichern",
         "compare": "Unterschiede\nsehen",
         "both-like": "Gemeinsames\nfinden",
         "edit-person": "Fotos und\nIcons wählen"
      ],
      "fr": [
         "home": "Mémorise\nles goûts",
         "person": "Garde les goûts\npar personne",
         "compare": "Vois les\ndifférences",
         "both-like": "Trouvez vos\nenvies communes",
         "edit-person": "Choisis photos\net icônes"
      ],
      "ko": [
         "home": "좋고 싫은 걸\n기억해요",
         "person": "사람별로\n남겨요",
         "compare": "둘의 차이를\n확인해요",
         "both-like": "함께 즐길 것을\n찾아요",
         "edit-person": "사진도 아이콘도\n나답게"
      ],
      "sv": [
         "home": "Minns\nsmaker",
         "person": "Spara per\nperson",
         "compare": "Se\nskillnader",
         "both-like": "Hitta gemensamt\ngillande",
         "edit-person": "Välj foton\noch ikoner"
      ],
      "zh-Hans": [
         "home": "记住喜欢\n和不喜欢",
         "person": "按人记录\n偏好",
         "compare": "看见两人的\n不同",
         "both-like": "找到一起\n喜欢的事",
         "edit-person": "照片头像\n都自选"
      ],
      "zh-Hant": [
         "home": "記住喜歡\n和不喜歡",
         "person": "按人記錄\n偏好",
         "compare": "看見兩人的\n不同",
         "both-like": "找到一起\n喜歡的事",
         "edit-person": "照片頭像\n都自選"
      ],
      "ar": [
         "home": "تذكّر\nالتفضيلات",
         "person": "احفظ لكل\nشخص",
         "compare": "شاهد\nالاختلافات",
         "both-like": "اعثر على\nالمشترك",
         "edit-person": "اختر الصور\nوالأيقونات"
      ],
      "el": [
         "home": "Γούστα\nστη μνήμη",
         "person": "Ανά άτομο",
         "compare": "Δες\nδιαφορές",
         "both-like": "Κοινά\nγούστα",
         "edit-person": "Φωτό\nεικονίδια"
      ]
   ]

   return localized[language]?[slideKey]
}

func normalizedLocale(_ locale: String) -> String {
   if locale == "zh-Hans" || locale == "zh-Hant" {
      return locale
   }

   if locale == "en-US" || locale == "en" {
      return "en"
   }

   return locale.split(separator: "-").first.map(String.init) ?? locale
}

func comparableHeadlineLength(_ headline: String) -> Int {
   headline.unicodeScalars.filter { scalar in
      !CharacterSet.whitespacesAndNewlines.contains(scalar)
   }.count
}

func drawPhone(_ screenshot: NSImage, size: NSSize, slide: SlideSpec, slideIndex: Int, locale: String, variant: VariantSpec) {
   let width = adjustedPhoneWidth(for: variant, slideIndex: slideIndex)
   let height = width * screenshot.size.height / screenshot.size.width
   let centerX = adjustedPhoneCenterX(for: variant, slideIndex: slideIndex)
   let bottom = adjustedPhoneBottom(for: variant, slideIndex: slideIndex, locale: locale)
   let centerY = bottom + height / 2
   let rotation = variant.phoneRotations[slideIndex] * .pi / 180
   let radius = width * 0.074
   let haloColor = variant.usesVividBackground ? NSColor.white : slide.accent
   let strokeColor = variant.usesVividBackground ? NSColor.white : slide.secondaryAccent
   let frameThickness = variant.usesVividBackground ? width * 0.034 : 0

   NSGraphicsContext.saveGraphicsState()
   guard let context = NSGraphicsContext.current?.cgContext else {
      NSGraphicsContext.restoreGraphicsState()
      return
   }

   context.translateBy(x: centerX, y: centerY)
   context.rotate(by: rotation)

   let rect = NSRect(x: -width / 2, y: -height / 2, width: width, height: height)
   let screenRect = rect.insetBy(dx: frameThickness, dy: frameThickness)
   let screenRadius = max(12, radius - frameThickness * 0.55)
   let haloRect = rect.insetBy(dx: -width * 0.025, dy: -width * 0.025)
   let haloPath = NSBezierPath(roundedRect: haloRect, xRadius: radius * 1.25, yRadius: radius * 1.25)
   haloColor.withAlphaComponent(variant.usesVividBackground ? 0.24 : 0.14).setFill()
   haloPath.fill()

   let shadowPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
   let shadow = NSShadow()
   shadow.shadowBlurRadius = width * 0.095
   shadow.shadowOffset = NSSize(width: width * 0.018, height: -width * 0.030)
   shadow.shadowColor = NSColor.black.withAlphaComponent(variant.usesVividBackground ? 0.28 : 0.15)
   shadow.set()
   (variant.usesVividBackground ? color("#050505") : NSColor.white).setFill()
   shadowPath.fill()
   NSShadow().set()

   NSGraphicsContext.saveGraphicsState()
   let clipPath = NSBezierPath(roundedRect: screenRect, xRadius: screenRadius, yRadius: screenRadius)
   clipPath.addClip()
   NSColor.white.setFill()
   screenRect.fill()
   screenshot.draw(in: screenRect, from: NSRect(origin: .zero, size: screenshot.size), operation: .sourceOver, fraction: 1)
   NSGraphicsContext.restoreGraphicsState()

   if variant.usesVividBackground {
      NSColor.white.withAlphaComponent(0.10).setStroke()
      let innerHighlightPath = NSBezierPath(roundedRect: screenRect.insetBy(dx: -1, dy: -1), xRadius: screenRadius, yRadius: screenRadius)
      innerHighlightPath.lineWidth = 2
      innerHighlightPath.stroke()
   }

   (variant.usesVividBackground ? NSColor.black : strokeColor).withAlphaComponent(variant.usesVividBackground ? 0.60 : 0.20).setStroke()
   let strokePath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
   strokePath.lineWidth = variant.usesVividBackground ? 4 : 2
   strokePath.stroke()

   NSGraphicsContext.restoreGraphicsState()
}

func adjustedPhoneWidth(for variant: VariantSpec, slideIndex: Int) -> CGFloat {
   guard variant.folderName == "proposal-04-playful-tilt" else {
      return variant.phoneWidths[slideIndex]
   }

   if slideIndex == 0 {
      return variant.phoneWidths[slideIndex] * 1.08
   }

   return variant.phoneWidths[slideIndex]
}

func adjustedPhoneCenterX(for variant: VariantSpec, slideIndex: Int) -> CGFloat {
   guard variant.folderName == "proposal-04-playful-tilt" else {
      return variant.phoneCenterX[slideIndex]
   }

   if slideIndex == 0 {
      return variant.phoneCenterX[slideIndex] - 70
   }

   return variant.phoneCenterX[slideIndex]
}

func adjustedPhoneBottom(for variant: VariantSpec, slideIndex: Int, locale: String) -> CGFloat {
   guard variant.folderName == "proposal-04-playful-tilt" else {
      return variant.phoneBottom[slideIndex]
   }

   if slideIndex == 0 {
      return variant.phoneBottom[slideIndex] - 95
   }

   if normalizedLocale(locale) != "ja", slideIndex == 2 {
      return variant.phoneBottom[slideIndex] + 190
   }

   if normalizedLocale(locale) != "ja", slideIndex == 3 {
      return variant.phoneBottom[slideIndex] + 260
   }

   return variant.phoneBottom[slideIndex]
}

func drawSoftCircle(center: NSPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
   let steps = 14

   for step in stride(from: steps, through: 1, by: -1) {
      let progress = CGFloat(step) / CGFloat(steps)
      let currentRadius = radius * progress
      let currentAlpha = alpha * pow(progress, 2.2) / CGFloat(steps) * 2.2
      color.withAlphaComponent(currentAlpha).setFill()
      NSBezierPath(ovalIn: NSRect(
         x: center.x - currentRadius,
         y: center.y - currentRadius,
         width: currentRadius * 2,
         height: currentRadius * 2
      )).fill()
   }
}

func drawSparkles(size: NSSize, color: NSColor, points: [NSPoint]) {
   for (index, point) in points.enumerated() {
      let long = size.width * (index == 0 ? 0.038 : 0.028)
      let short = long * 0.38
      let path = NSBezierPath()
      path.move(to: NSPoint(x: point.x, y: point.y + long))
      path.line(to: NSPoint(x: point.x + short, y: point.y + short))
      path.line(to: NSPoint(x: point.x + long, y: point.y))
      path.line(to: NSPoint(x: point.x + short, y: point.y - short))
      path.line(to: NSPoint(x: point.x, y: point.y - long))
      path.line(to: NSPoint(x: point.x - short, y: point.y - short))
      path.line(to: NSPoint(x: point.x - long, y: point.y))
      path.line(to: NSPoint(x: point.x - short, y: point.y + short))
      path.close()
      color.withAlphaComponent(index == 0 ? 0.28 : 0.20).setFill()
      path.fill()
   }
}

func drawAngledBand(size: NSSize, yRatio: CGFloat, height: CGFloat, color: NSColor, angle: CGFloat) {
   NSGraphicsContext.saveGraphicsState()
   guard let context = NSGraphicsContext.current?.cgContext else {
      NSGraphicsContext.restoreGraphicsState()
      return
   }

   context.translateBy(x: size.width / 2, y: size.height * yRatio)
   context.rotate(by: angle * .pi / 180)
   color.setFill()
   NSBezierPath(roundedRect: NSRect(x: -size.width, y: -height / 2, width: size.width * 2, height: height), xRadius: height / 2, yRadius: height / 2).fill()
   NSGraphicsContext.restoreGraphicsState()
}

func drawRing(center: NSPoint, radius: CGFloat, color: NSColor, lineWidth: CGFloat) {
   color.setStroke()
   let path = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
   path.lineWidth = lineWidth
   path.stroke()
}

func drawWave(size: NSSize, color: NSColor, yRatio: CGFloat, slideIndex: Int) {
   let path = NSBezierPath()
   path.lineWidth = 10
   path.lineCapStyle = .round
   color.setStroke()

   let y = size.height * yRatio
   let offset = CGFloat(slideIndex % 3) * size.height * 0.018
   path.move(to: NSPoint(x: size.width * -0.05, y: y + offset))
   path.curve(
      to: NSPoint(x: size.width * 1.05, y: y - offset),
      controlPoint1: NSPoint(x: size.width * 0.24, y: y + size.height * 0.10),
      controlPoint2: NSPoint(x: size.width * 0.72, y: y - size.height * 0.11)
   )
   path.stroke()
}

func drawBubbles(size: NSSize, color: NSColor, secondaryColor: NSColor, slideIndex: Int) {
   let specs: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
      (0.12, 0.44, 0.035, color),
      (0.20, 0.58, 0.018, secondaryColor),
      (0.88, 0.70, 0.025, color),
      (0.78, 0.28, 0.032, secondaryColor),
      (0.92, 0.18, 0.018, color)
   ]

   for (x, y, radius, bubbleColor) in specs {
      let center = point(size, x + CGFloat(slideIndex % 2) * 0.015, y)
      bubbleColor.withAlphaComponent(0.18).setFill()
      NSBezierPath(ovalIn: NSRect(
         x: center.x - size.width * radius,
         y: center.y - size.width * radius,
         width: size.width * radius * 2,
         height: size.width * radius * 2
      )).fill()
   }
}

func drawHearts(size: NSSize, color: NSColor, slideIndex: Int) {
   let centers = [
      point(size, 0.13, 0.68),
      point(size, 0.86, 0.83),
      point(size, 0.18, 0.23)
   ]

   for (index, center) in centers.enumerated() {
      drawHeart(center: center, size: size.width * (index == slideIndex % 3 ? 0.046 : 0.034), color: color)
   }
}

func drawHeart(center: NSPoint, size: CGFloat, color: NSColor) {
   let path = NSBezierPath()
   path.move(to: NSPoint(x: center.x, y: center.y - size * 0.38))
   path.curve(
      to: NSPoint(x: center.x - size * 0.50, y: center.y + size * 0.10),
      controlPoint1: NSPoint(x: center.x - size * 0.18, y: center.y - size * 0.18),
      controlPoint2: NSPoint(x: center.x - size * 0.50, y: center.y - size * 0.02)
   )
   path.curve(
      to: NSPoint(x: center.x, y: center.y + size * 0.34),
      controlPoint1: NSPoint(x: center.x - size * 0.50, y: center.y + size * 0.34),
      controlPoint2: NSPoint(x: center.x - size * 0.15, y: center.y + size * 0.44)
   )
   path.curve(
      to: NSPoint(x: center.x + size * 0.50, y: center.y + size * 0.10),
      controlPoint1: NSPoint(x: center.x + size * 0.15, y: center.y + size * 0.44),
      controlPoint2: NSPoint(x: center.x + size * 0.50, y: center.y + size * 0.34)
   )
   path.curve(
      to: NSPoint(x: center.x, y: center.y - size * 0.38),
      controlPoint1: NSPoint(x: center.x + size * 0.50, y: center.y - size * 0.02),
      controlPoint2: NSPoint(x: center.x + size * 0.18, y: center.y - size * 0.18)
   )
   path.close()
   color.setFill()
   path.fill()
}

func savePNG(_ image: NSImage, to outputURL: URL) throws {
   var proposedRect = NSRect(origin: .zero, size: image.size)
   guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 3, userInfo: [
         NSLocalizedDescriptionKey: "Could not create CGImage for \(outputURL.path)"
      ])
   }

   let width = cgImage.width
   let height = cgImage.height
   let colorSpace = CGColorSpaceCreateDeviceRGB()
   guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
   ) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 6, userInfo: [
         NSLocalizedDescriptionKey: "Could not create flattened context for \(outputURL.path)"
      ])
   }

   let rect = CGRect(x: 0, y: 0, width: width, height: height)
   context.interpolationQuality = .high
   context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
   context.fill(rect)
   context.draw(cgImage, in: rect)

   guard let flattenedImage = context.makeImage(),
         let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 7, userInfo: [
         NSLocalizedDescriptionKey: "Could not create PNG destination for \(outputURL.path)"
      ])
   }

   CGImageDestinationAddImage(destination, flattenedImage, nil)
   guard CGImageDestinationFinalize(destination) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 8, userInfo: [
         NSLocalizedDescriptionKey: "Could not write \(outputURL.path)"
      ])
   }
}

func point(_ size: NSSize, _ xRatio: CGFloat, _ yRatio: CGFloat) -> NSPoint {
   NSPoint(x: size.width * xRatio, y: size.height * yRatio)
}

func color(_ hex: String) -> NSColor {
   let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
   let scanner = Scanner(string: cleaned)
   var value: UInt64 = 0
   scanner.scanHexInt64(&value)

   let red = CGFloat((value >> 16) & 0xFF) / 255.0
   let green = CGFloat((value >> 8) & 0xFF) / 255.0
   let blue = CGFloat(value & 0xFF) / 255.0
   return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
}
