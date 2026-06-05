import SwiftUI

struct LikehateFloatingBackgroundView: View {
   enum BlurPlacement: CaseIterable, Hashable {
      case center
      case full
      case top
      case none
   }

   @Environment(\.accessibilityReduceMotion) private var reduceMotion

   private let blurPlacement: BlurPlacement
   private let ignoresSafeAreaEdges: Bool
   private let isAnimationEnabled: Bool

   init(
      blurPlacement: BlurPlacement = .center,
      ignoresSafeAreaEdges: Bool = true,
      isAnimationEnabled: Bool = true
   ) {
      self.blurPlacement = blurPlacement
      self.ignoresSafeAreaEdges = ignoresSafeAreaEdges
      self.isAnimationEnabled = isAnimationEnabled
   }

   @ViewBuilder
   var body: some View {
      if ignoresSafeAreaEdges {
         floatingContent
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
      } else {
         floatingContent
            .allowsHitTesting(false)
            .accessibilityHidden(true)
      }
   }

   @ViewBuilder
   private var floatingContent: some View {
      let pausesAnimation = reduceMotion || !isAnimationEnabled

      TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: pausesAnimation)) { context in
         GeometryReader { proxy in
            ZStack {
               LikehateFloatingArtworkWash()

               ForEach(LikehateFloatingElement.backgroundElements) { element in
                  LikehateFloatingElementView(
                     element: element,
                     time: pausesAnimation ? 0 : context.date.timeIntervalSinceReferenceDate,
                     containerSize: proxy.size,
                     reduceMotion: pausesAnimation
                  )
               }

               LikehateFloatingBackgroundBlur(
                  placement: blurPlacement,
                  containerHeight: proxy.size.height
               )
               .allowsHitTesting(false)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
         }
      }
   }
}

private struct LikehateFloatingBackgroundBlur: View {
   let placement: LikehateFloatingBackgroundView.BlurPlacement
   let containerHeight: CGFloat

   var body: some View {
      switch placement {
      case .center, .top:
         VStack(spacing: 0) {
            if placement == .center {
               Spacer(minLength: 0)
            }

            LikehateTheme.background
               .opacity(0.68)
               .frame(height: min(containerHeight * 0.38, 280))
               .blur(radius: 30)

            Spacer(minLength: 0)
         }
      case .full:
         LikehateTheme.background
            .opacity(0.56)
            .blur(radius: 30)
      case .none:
         EmptyView()
      }
   }
}

private struct LikehateFloatingArtworkWash: View {
   var body: some View {
      LinearGradient(
         colors: [
            LikehateTheme.likeAccent.opacity(0.16),
            LikehateTheme.sparkleAccent.opacity(0.08),
            .clear,
            LikehateTheme.hateAccent.opacity(0.10),
            Color(red: 0.96, green: 0.54, blue: 0.82).opacity(0.08)
         ],
         startPoint: .top,
         endPoint: .bottom
      )
   }
}

private struct LikehateFloatingElementView: View {
   let element: LikehateFloatingElement
   let time: TimeInterval
   let containerSize: CGSize
   let reduceMotion: Bool

   var body: some View {
      elementContent
         .frame(width: diameter, height: diameter)
         .position(position)
         .rotationEffect(.degrees(rotationDegrees))
         .opacity(opacity)
         .shadow(
            color: .black.opacity(0.07),
            radius: max(2, diameter * 0.06),
            y: max(1, diameter * 0.03)
         )
   }

   @ViewBuilder
   private var elementContent: some View {
      switch element.kind {
      case .symbol(let systemName):
         ZStack {
            Circle()
               .fill(element.palette.fill)
               .overlay {
                  Circle()
                     .stroke(element.palette.stroke, lineWidth: max(1.2, diameter * 0.035))
               }

            Image(systemName: systemName)
               .font(.system(size: diameter * 0.42, weight: .bold, design: .rounded))
               .foregroundStyle(element.palette.symbol)
         }
      case .circle:
         Circle()
            .fill(element.palette.fill)
            .overlay {
               Circle()
                  .stroke(element.palette.stroke, lineWidth: max(1, diameter * 0.03))
            }
      case .ring:
         Circle()
            .fill(element.palette.fill.opacity(0.18))
            .overlay {
               Circle()
                  .stroke(element.palette.stroke, lineWidth: max(1.8, diameter * 0.08))
            }
      case .pairedDots:
         ZStack {
            Circle()
               .fill(element.palette.fill)
               .frame(width: diameter * 0.50, height: diameter * 0.50)
               .offset(x: -diameter * 0.18, y: -diameter * 0.10)

            Circle()
               .fill(element.palette.symbol.opacity(0.82))
               .frame(width: diameter * 0.36, height: diameter * 0.36)
               .offset(x: diameter * 0.18, y: diameter * 0.14)
         }
      case .sparkle:
         Image(systemName: "sparkles")
            .font(.system(size: diameter * 0.58, weight: .semibold, design: .rounded))
            .foregroundStyle(element.palette.fill)
            .shadow(color: element.palette.symbol.opacity(0.35), radius: 5)
      }
   }

   private var diameter: CGFloat {
      max(10, min(containerSize.width, containerSize.height) * element.relativeSize)
   }

   private var position: CGPoint {
      let base = min(containerSize.width, containerSize.height)
      let seconds = CGFloat(time.truncatingRemainder(dividingBy: 1_000))
      let phase = element.phase * .pi * 2
      let driftX = sin(seconds * element.speed + phase) * element.horizontalDrift * base
      let driftY = cos(seconds * element.speed * 0.78 + phase) * element.verticalDrift * base
      let flow = sin(seconds * 0.18 + phase * 0.7) * element.flowDrift * base

      return CGPoint(
         x: containerSize.width * element.x + driftX,
         y: containerSize.height * element.y + driftY + flow
      )
   }

   private var rotationDegrees: Double {
      guard !reduceMotion else { return element.rotationDegrees }
      let seconds = time.truncatingRemainder(dividingBy: 1_000)
      return element.rotationDegrees + sin(seconds * element.speed + Double(element.phase) * .pi) * 7
   }

   private var opacity: Double {
      guard !reduceMotion else { return element.opacity }
      let seconds = time.truncatingRemainder(dividingBy: 1_000)
      let pulse = sin(seconds * Double(element.speed) * 0.72 + Double(element.phase) * .pi * 2)
      return element.opacity * (0.88 + 0.12 * ((pulse + 1) / 2))
   }
}

private struct LikehateFloatingElement: Identifiable {
   enum Kind {
      case symbol(String)
      case circle
      case ring
      case pairedDots
      case sparkle
   }

   let id: String
   let kind: Kind
   let x: CGFloat
   let y: CGFloat
   let relativeSize: CGFloat
   let horizontalDrift: CGFloat
   let verticalDrift: CGFloat
   let flowDrift: CGFloat
   let speed: CGFloat
   let phase: CGFloat
   let rotationDegrees: Double
   let opacity: Double
   let palette: LikehateFloatingPalette

   init(
      id: String,
      kind: Kind,
      x: CGFloat,
      y: CGFloat,
      size: CGFloat,
      palette: LikehateFloatingPalette,
      opacity: Double,
      horizontalDrift: CGFloat = 0.05,
      verticalDrift: CGFloat = 0.04,
      flowDrift: CGFloat = 0.04,
      speed: CGFloat = 0.38,
      phase: CGFloat,
      rotationDegrees: Double = 0
   ) {
      self.id = id
      self.kind = kind
      self.x = x
      self.y = y
      self.relativeSize = size
      self.horizontalDrift = horizontalDrift
      self.verticalDrift = verticalDrift
      self.flowDrift = flowDrift
      self.speed = speed
      self.phase = phase
      self.rotationDegrees = rotationDegrees
      self.opacity = opacity
      self.palette = palette
   }

   static let backgroundElements: [LikehateFloatingElement] = [
      .init(
         id: "top-heart-left", kind: .symbol("heart.fill"), x: 0.15, y: 0.10, size: 0.25,
         palette: LikehateFloatingPalettes.petal, opacity: 0.88, horizontalDrift: 0.08,
         verticalDrift: 0.04, flowDrift: 0.05, speed: 0.34, phase: 0.10, rotationDegrees: -12),
      .init(
         id: "top-star-center", kind: .symbol("star.fill"), x: 0.44, y: 0.08, size: 0.14,
         palette: LikehateFloatingPalettes.lemon, opacity: 0.70, horizontalDrift: 0.06,
         speed: 0.42, phase: 0.55, rotationDegrees: 18),
      .init(
         id: "top-bolt-right", kind: .symbol("bolt.fill"), x: 0.78, y: 0.14, size: 0.22,
         palette: LikehateFloatingPalettes.sky, opacity: 0.72, horizontalDrift: 0.07,
         flowDrift: 0.05, speed: 0.30, phase: 0.72, rotationDegrees: 8),
      .init(
         id: "upper-gift-right", kind: .symbol("gift.fill"), x: 0.94, y: 0.28, size: 0.18,
         palette: LikehateFloatingPalettes.mint, opacity: 0.76, speed: 0.48, phase: 0.24,
         rotationDegrees: 10),
      .init(
         id: "upper-coral-dots", kind: .pairedDots, x: 0.54, y: 0.25, size: 0.11,
         palette: LikehateFloatingPalettes.coral, opacity: 0.62, horizontalDrift: 0.07,
         flowDrift: 0.05, speed: 0.40, phase: 0.36, rotationDegrees: -8),
      .init(
         id: "left-blue-ring", kind: .ring, x: 0.02, y: 0.35, size: 0.13,
         palette: LikehateFloatingPalettes.sky, opacity: 0.46, verticalDrift: 0.05,
         speed: 0.36, phase: 0.82, rotationDegrees: -22),
      .init(
         id: "upper-lemon-sparkles", kind: .sparkle, x: 0.29, y: 0.29, size: 0.11,
         palette: LikehateFloatingPalettes.lemon, opacity: 0.62, speed: 0.46, phase: 0.64),
      .init(
         id: "upper-right-leaf", kind: .symbol("leaf.fill"), x: 0.86, y: 0.38, size: 0.10,
         palette: LikehateFloatingPalettes.mint, opacity: 0.48, horizontalDrift: 0.04,
         flowDrift: 0.03, speed: 0.41, phase: 0.69),
      .init(
         id: "upper-left-petal-sparkle-small", kind: .sparkle, x: 0.13, y: 0.27, size: 0.075,
         palette: LikehateFloatingPalettes.petal, opacity: 0.50, horizontalDrift: 0.04,
         flowDrift: 0.03, speed: 0.49, phase: 0.31),
      .init(
         id: "middle-right-moon", kind: .symbol("moon.fill"), x: 0.82, y: 0.45, size: 0.10,
         palette: LikehateFloatingPalettes.sky, opacity: 0.44, horizontalDrift: 0.035,
         flowDrift: 0.025, speed: 0.39, phase: 0.06),
      .init(
         id: "middle-left-coral-ring", kind: .ring, x: 0.18, y: 0.42, size: 0.15,
         palette: LikehateFloatingPalettes.coral, opacity: 0.34, horizontalDrift: 0.04,
         verticalDrift: 0.04, speed: 0.37, phase: 0.47, rotationDegrees: -10),
      .init(
         id: "middle-left-pink-circle", kind: .circle, x: 0.10, y: 0.49, size: 0.10,
         palette: LikehateFloatingPalettes.petal, opacity: 0.32, horizontalDrift: 0.04,
         phase: 0.18),
      .init(
         id: "middle-right-petal-ring", kind: .ring, x: 0.92, y: 0.52, size: 0.14,
         palette: LikehateFloatingPalettes.petal, opacity: 0.36, verticalDrift: 0.05,
         speed: 0.43, phase: 0.78, rotationDegrees: 18),
      .init(
         id: "lower-center-sky-ring", kind: .ring, x: 0.55, y: 0.62, size: 0.13,
         palette: LikehateFloatingPalettes.sky, opacity: 0.30, horizontalDrift: 0.04,
         verticalDrift: 0.04, speed: 0.35, phase: 0.21, rotationDegrees: 14),
      .init(
         id: "bottom-heart-right", kind: .symbol("heart.fill"), x: 0.82, y: 0.78, size: 0.30,
         palette: LikehateFloatingPalettes.petal, opacity: 0.84, horizontalDrift: 0.08,
         verticalDrift: 0.05, flowDrift: 0.05, speed: 0.33, phase: 0.45, rotationDegrees: 12),
      .init(
         id: "bottom-star-left", kind: .symbol("star.fill"), x: 0.21, y: 0.75, size: 0.22,
         palette: LikehateFloatingPalettes.lemon, opacity: 0.68, horizontalDrift: 0.07,
         verticalDrift: 0.05, flowDrift: 0.05, speed: 0.35, phase: 0.16, rotationDegrees: -10),
      .init(
         id: "lower-bolt-left", kind: .symbol("bolt.fill"), x: 0.07, y: 0.65, size: 0.17,
         palette: LikehateFloatingPalettes.coral, opacity: 0.64, speed: 0.47, phase: 0.62,
         rotationDegrees: -16),
      .init(
         id: "lower-mint-dots", kind: .pairedDots, x: 0.42, y: 0.72, size: 0.11,
         palette: LikehateFloatingPalettes.mint, opacity: 0.58, horizontalDrift: 0.06,
         speed: 0.40, phase: 0.30, rotationDegrees: 9),
      .init(
         id: "lower-petal-sparkles", kind: .sparkle, x: 0.66, y: 0.68, size: 0.11,
         palette: LikehateFloatingPalettes.petal, opacity: 0.60, speed: 0.45, phase: 0.08),
      .init(
         id: "lower-left-heart-small", kind: .symbol("heart.circle.fill"), x: 0.16, y: 0.86, size: 0.10,
         palette: LikehateFloatingPalettes.mint, opacity: 0.56, horizontalDrift: 0.04,
         speed: 0.44, phase: 0.27),
      .init(
         id: "lower-right-coral-dot-small", kind: .circle, x: 0.73, y: 0.88, size: 0.075,
         palette: LikehateFloatingPalettes.coral, opacity: 0.46, horizontalDrift: 0.04,
         flowDrift: 0.03, speed: 0.41, phase: 0.59),
      .init(
         id: "bottom-coral-circle", kind: .circle, x: 0.94, y: 0.94, size: 0.11,
         palette: LikehateFloatingPalettes.coral, opacity: 0.54, horizontalDrift: 0.04,
         phase: 0.86),
      .init(
         id: "bottom-sky-ring", kind: .ring, x: 0.31, y: 0.94, size: 0.18,
         palette: LikehateFloatingPalettes.sky, opacity: 0.58, horizontalDrift: 0.06,
         verticalDrift: 0.05, speed: 0.34, phase: 0.52, rotationDegrees: -12),
      .init(
         id: "bottom-star-small", kind: .symbol("star.circle.fill"), x: 0.57, y: 0.91, size: 0.13,
         palette: LikehateFloatingPalettes.lemon, opacity: 0.66, speed: 0.42, phase: 0.94,
         rotationDegrees: 5)
   ]
}

private struct LikehateFloatingPalette {
   let fill: Color
   let stroke: Color
   let symbol: Color
}

private enum LikehateFloatingPalettes {
   static let petal = LikehateFloatingPalette(
      fill: LikehateTheme.likeAccent.opacity(0.92),
      stroke: Color(red: 1.00, green: 0.84, blue: 0.89).opacity(0.78),
      symbol: .white
   )

   static let sky = LikehateFloatingPalette(
      fill: LikehateTheme.hateAccent.opacity(0.82),
      stroke: Color(red: 0.82, green: 0.93, blue: 1.00).opacity(0.70),
      symbol: .white
   )

   static let lemon = LikehateFloatingPalette(
      fill: LikehateTheme.sparkleAccent.opacity(0.92),
      stroke: .white.opacity(0.62),
      symbol: Color(red: 0.36, green: 0.26, blue: 0.10)
   )

   static let mint = LikehateFloatingPalette(
      fill: Color(red: 0.45, green: 0.76, blue: 0.62).opacity(0.84),
      stroke: .white.opacity(0.66),
      symbol: .white
   )

   static let coral = LikehateFloatingPalette(
      fill: Color(red: 1.00, green: 0.61, blue: 0.39).opacity(0.78),
      stroke: .white.opacity(0.62),
      symbol: Color(red: 1.00, green: 0.86, blue: 0.62)
   )
}

#if DEBUG
#Preview("Likehate Floating Background") {
   LikehateFloatingBackgroundView()
      .background(LikehateTheme.background)
}
#endif
