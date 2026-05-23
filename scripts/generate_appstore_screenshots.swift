import AppKit
import Foundation

struct SlideText {
   let key: String
   let fileStem: String
   let headline: [String: String]
   let subcopy: [String: String]
}

struct Palette {
   let background: NSColor
   let wash: NSColor
   let accent: NSColor
   let text: NSColor
   let subtext: NSColor
}

struct DeviceSpec {
   let name: String
   let inputDirectory: String
   let outputDirectory: String
   let screenshotWidthRatio: CGFloat
   let topPaddingRatio: CGFloat
   let headlineSizeRatio: CGFloat
   let subcopySizeRatio: CGFloat
   let screenshotTopRatio: CGFloat
   let cornerRadiusRatio: CGFloat
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let slides: [SlideText] = [
   SlideText(
      key: "home",
      fileStem: "01_home",
      headline: [
         "ja": "好きも嫌いも、\nまとめてメモ。",
         "en": "Likes and dislikes,\nall in one place."
      ],
      subcopy: [
         "ja": "好きなもの・苦手なものを、シンプルに残せます。",
         "en": "Keep track of what you love and what you’d rather avoid."
      ]
   ),
   SlideText(
      key: "likes_list",
      fileStem: "02_likes_list",
      headline: [
         "ja": "好きなものを、\n忘れずに残せる。",
         "en": "Remember\nwhat you like."
      ],
      subcopy: [
         "ja": "カフェ、散歩、映画など、自分の好きをまとめて記録。",
         "en": "Save cafés, walks, movies, and the little things you enjoy."
      ]
   ),
   SlideText(
      key: "dislikes_list",
      fileStem: "03_dislikes_list",
      headline: [
         "ja": "苦手なものも、\nちゃんと覚えておける。",
         "en": "Remember\nwhat you dislike."
      ],
      subcopy: [
         "ja": "雨の日、早起き、人混みなど、避けたいものも整理。",
         "en": "Keep rainy days, early mornings, crowds, and more in one place."
      ]
   ),
   SlideText(
      key: "add_like",
      fileStem: "04_add_like",
      headline: [
         "ja": "思いついたら、\nすぐ登録。",
         "en": "Add a like\nin seconds."
      ],
      subcopy: [
         "ja": "入力してボタンを押すだけで、好きなものを追加。",
         "en": "Type it in, tap the button, and save what makes you happy."
      ]
   ),
   SlideText(
      key: "add_dislike",
      fileStem: "05_add_dislike",
      headline: [
         "ja": "嫌いなものも、\nかんたんに追加。",
         "en": "Add a dislike\njust as easily."
      ],
      subcopy: [
         "ja": "苦手なものを残して、自分の傾向を見返せます。",
         "en": "Save what you’d rather avoid and understand your preferences."
      ]
   )
]

let palettes: [Palette] = [
   Palette(background: color("#F7F4F1"), wash: color("#FFE5EA"), accent: color("#E85D75"), text: color("#332B2F"), subtext: color("#6E6267")),
   Palette(background: color("#F4F6F3"), wash: color("#FFE1D6"), accent: color("#D96B55"), text: color("#2E312D"), subtext: color("#666B64")),
   Palette(background: color("#F8F1F5"), wash: color("#E8F0FF"), accent: color("#8B6FD6"), text: color("#302C36"), subtext: color("#696171")),
   Palette(background: color("#FFF8EC"), wash: color("#FFD9C8"), accent: color("#E07A5F"), text: color("#322D28"), subtext: color("#6F665D")),
   Palette(background: color("#F3F6F8"), wash: color("#FCE2F0"), accent: color("#D75D93"), text: color("#2C3034"), subtext: color("#626C73"))
]

let devices = [
   DeviceSpec(
      name: "iphone",
      inputDirectory: "public/screenshots/iphone",
      outputDirectory: "exports/app-store-screenshots/iphone",
      screenshotWidthRatio: 0.73,
      topPaddingRatio: 0.065,
      headlineSizeRatio: 0.079,
      subcopySizeRatio: 0.038,
      screenshotTopRatio: 0.268,
      cornerRadiusRatio: 0.055
   ),
   DeviceSpec(
      name: "ipad",
      inputDirectory: "public/screenshots/ipad",
      outputDirectory: "exports/app-store-screenshots/ipad",
      screenshotWidthRatio: 0.71,
      topPaddingRatio: 0.055,
      headlineSizeRatio: 0.056,
      subcopySizeRatio: 0.033,
      screenshotTopRatio: 0.285,
      cornerRadiusRatio: 0.035
   )
]

let locales = ["ja", "en"]
let datePattern = #"(\d{4}-\d{2}-\d{2}) at (\d{2})\.(\d{2})\.(\d{2})"#
let dateRegex = try NSRegularExpression(pattern: datePattern)

for device in devices {
   for locale in locales {
      let inputDirectory = root.appendingPathComponent(device.inputDirectory).appendingPathComponent(locale)
      let outputDirectory = root.appendingPathComponent(device.outputDirectory).appendingPathComponent(locale)
      try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

      let inputFiles = try sortedScreenshotFiles(in: inputDirectory)
      guard inputFiles.count >= slides.count else {
         throw NSError(domain: "GenerateAppStoreScreenshots", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "\(inputDirectory.path) has \(inputFiles.count) screenshots, expected at least \(slides.count)."
         ])
      }

      for (index, slide) in slides.enumerated() {
         let image = try render(
            screenshotURL: inputFiles[index],
            slide: slide,
            slideIndex: index,
            locale: locale,
            device: device
         )

         let outputName = "\(slide.fileStem)_appstore_\(locale).png"
         let outputURL = outputDirectory.appendingPathComponent(outputName)
         try savePNG(image, to: outputURL)
         print("\(device.name)/\(locale) \(index + 1): \(inputFiles[index].lastPathComponent) -> \(outputURL.path)")
      }
   }
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
   slide: SlideText,
   slideIndex: Int,
   locale: String,
   device: DeviceSpec
) throws -> NSImage {
   var screenshot = try loadBitmapImage(from: screenshotURL)
   if device.name == "iphone", screenshot.size.width > screenshot.size.height {
      screenshot = rotateCounterClockwise(screenshot)
   }

   let size = screenshot.size
   let palette = palettes[slideIndex % palettes.count]
   let image = NSImage(size: size)

   image.lockFocus()
   defer { image.unlockFocus() }

   NSGraphicsContext.current?.imageInterpolation = .high
   drawBackground(size: size, palette: palette, slideIndex: slideIndex)
   drawScreenshot(screenshot, canvasSize: size, device: device, palette: palette, slideIndex: slideIndex)
   drawCopy(size: size, slide: slide, locale: locale, device: device, palette: palette)

   return image
}

func rotateCounterClockwise(_ image: NSImage) -> NSImage {
   let newSize = NSSize(width: image.size.height, height: image.size.width)
   let rotated = NSImage(size: newSize)

   rotated.lockFocus()
   defer { rotated.unlockFocus() }

   guard let context = NSGraphicsContext.current?.cgContext else {
      return image
   }

   context.translateBy(x: 0, y: newSize.height)
   context.rotate(by: -.pi / 2)
   image.draw(in: NSRect(origin: .zero, size: image.size), from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1)
   return rotated
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

func drawBackground(size: NSSize, palette: Palette, slideIndex: Int) {
   palette.background.setFill()
   NSRect(origin: .zero, size: size).fill()

   let washDiameter = size.width * (slideIndex % 2 == 0 ? 0.72 : 0.62)
   let washRect = NSRect(
      x: size.width * (slideIndex % 2 == 0 ? -0.18 : 0.62),
      y: size.height * 0.62,
      width: washDiameter,
      height: washDiameter
   )
   palette.wash.withAlphaComponent(0.62).setFill()
   NSBezierPath(ovalIn: washRect).fill()

   let accentDiameter = size.width * 0.22
   let accentRect = NSRect(
      x: size.width * (slideIndex % 2 == 0 ? 0.78 : -0.05),
      y: size.height * 0.08,
      width: accentDiameter,
      height: accentDiameter
   )
   palette.accent.withAlphaComponent(0.10).setFill()
   NSBezierPath(ovalIn: accentRect).fill()

   let stripePath = NSBezierPath()
   stripePath.lineWidth = max(5, size.width * 0.006)
   stripePath.lineCapStyle = .round
   palette.accent.withAlphaComponent(0.18).setStroke()
   let y = size.height * 0.58
   stripePath.move(to: NSPoint(x: size.width * 0.12, y: y))
   stripePath.curve(
      to: NSPoint(x: size.width * 0.88, y: y + size.height * 0.035),
      controlPoint1: NSPoint(x: size.width * 0.32, y: y + size.height * 0.08),
      controlPoint2: NSPoint(x: size.width * 0.65, y: y - size.height * 0.055)
   )
   stripePath.stroke()
}

func drawCopy(size: NSSize, slide: SlideText, locale: String, device: DeviceSpec, palette: Palette) {
   let margin = size.width * (device.name == "ipad" ? 0.095 : 0.085)
   let copyWidth = size.width - margin * 2
   let topPadding = size.height * device.topPaddingRatio

   let headlineParagraph = NSMutableParagraphStyle()
   headlineParagraph.alignment = .left
   headlineParagraph.lineBreakMode = .byWordWrapping
   headlineParagraph.lineSpacing = size.height * 0.006

   let headlineFont = NSFont.systemFont(ofSize: size.width * device.headlineSizeRatio, weight: .heavy)
   let headlineAttributes: [NSAttributedString.Key: Any] = [
      .font: headlineFont,
      .foregroundColor: palette.text,
      .paragraphStyle: headlineParagraph,
      .kern: -0.2
   ]

   let headline = slide.headline[locale] ?? ""
   let headlineRect = NSRect(
      x: margin,
      y: size.height - topPadding - size.height * 0.19,
      width: copyWidth,
      height: size.height * 0.22
   )
   NSAttributedString(string: headline, attributes: headlineAttributes).draw(
      with: headlineRect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
   )

   let subcopyParagraph = NSMutableParagraphStyle()
   subcopyParagraph.alignment = .left
   subcopyParagraph.lineBreakMode = .byWordWrapping
   subcopyParagraph.lineSpacing = size.height * 0.003

   let subcopyFont = NSFont.systemFont(ofSize: size.width * device.subcopySizeRatio, weight: .semibold)
   let subcopyAttributes: [NSAttributedString.Key: Any] = [
      .font: subcopyFont,
      .foregroundColor: palette.subtext,
      .paragraphStyle: subcopyParagraph
   ]

   let subcopy = slide.subcopy[locale] ?? ""
   let subcopyOffset = size.height * (device.name == "iphone" ? 0.008 : 0.032)
   let subcopyRect = NSRect(
      x: margin,
      y: headlineRect.minY - subcopyOffset,
      width: copyWidth * (device.name == "ipad" ? 0.92 : 0.96),
      height: size.height * 0.09
   )
   NSAttributedString(string: subcopy, attributes: subcopyAttributes).draw(
      with: subcopyRect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
   )
}

func drawScreenshot(
   _ screenshot: NSImage,
   canvasSize: NSSize,
   device: DeviceSpec,
   palette: Palette,
   slideIndex: Int
) {
   let targetWidth = canvasSize.width * device.screenshotWidthRatio
   let targetHeight = targetWidth * screenshot.size.height / screenshot.size.width
   let xOffset = canvasSize.width * (device.name == "ipad" ? 0.02 : 0.0) * (slideIndex % 2 == 0 ? 1 : -1)
   let x = (canvasSize.width - targetWidth) / 2 + xOffset
   let y = canvasSize.height * (1 - device.screenshotTopRatio) - targetHeight
   let rect = NSRect(x: x, y: y, width: targetWidth, height: targetHeight)
   let cornerRadius = canvasSize.width * device.cornerRadiusRatio

   let shadow = NSShadow()
   shadow.shadowBlurRadius = canvasSize.width * 0.045
   shadow.shadowOffset = NSSize(width: 0, height: -canvasSize.height * 0.012)
   shadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
   shadow.set()

   palette.accent.withAlphaComponent(0.12).setFill()
   NSBezierPath(roundedRect: rect.insetBy(dx: -canvasSize.width * 0.018, dy: -canvasSize.width * 0.018), xRadius: cornerRadius * 1.15, yRadius: cornerRadius * 1.15).fill()

   NSGraphicsContext.saveGraphicsState()
   let clipPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
   clipPath.addClip()
   NSColor.white.setFill()
   rect.fill()
   screenshot.draw(in: rect, from: NSRect(origin: .zero, size: screenshot.size), operation: .sourceOver, fraction: 1)
   NSGraphicsContext.restoreGraphicsState()

   NSShadow().set()
   palette.accent.withAlphaComponent(0.22).setStroke()
   let strokePath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
   strokePath.lineWidth = max(2, canvasSize.width * 0.002)
   strokePath.stroke()
}

func savePNG(_ image: NSImage, to outputURL: URL) throws {
   guard let tiff = image.tiffRepresentation,
         let bitmap = NSBitmapImageRep(data: tiff),
         let png = bitmap.representation(using: .png, properties: [:]) else {
      throw NSError(domain: "GenerateAppStoreScreenshots", code: 3, userInfo: [
         NSLocalizedDescriptionKey: "Could not encode \(outputURL.path)"
      ])
   }

   try png.write(to: outputURL, options: .atomic)
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
