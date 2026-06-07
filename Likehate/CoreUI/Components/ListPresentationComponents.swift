import SwiftUI

/// 一覧や比較詳細で使う、アプリ共通のやわらかいカードコンテナ。
struct AppSectionCard<Content: View>: View {
   @Environment(\.colorScheme) private var colorScheme

   private let content: Content

   init(@ViewBuilder content: () -> Content) {
      self.content = content()
   }

   var body: some View {
      content
         .padding(.vertical, 4)
         .background(LikehateTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
         .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
               .stroke(LikehateTheme.border, lineWidth: 1)
         }
         .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 14, x: 0, y: 8)
   }
}

/// 比較対象の2人を重なったアバターと名前で表示するヘッダー。
struct PersonPairHeaderView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPerson: Person
   let secondPerson: Person
   var avatarSize: CGFloat = 42

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(spacing: avatarSize >= 40 ? 14 : 10) {
         DiagonalOverlappingPersonAvatars(
            firstPerson: firstPerson,
            secondPerson: secondPerson,
            size: avatarSize,
            horizontalOffset: avatarSize * 0.38,
            verticalOffset: avatarSize * 0.24
         )

         HStack(spacing: 4) {
            Text(verbatim: firstPerson.displayName)
               .lineLimit(1)

            Text("PersonPairSeparator")
               .foregroundStyle(.tertiary)

            Text(verbatim: secondPerson.displayName)
               .lineLimit(1)
         }
         .layoutPriority(1)
      }
      .font(typography.subtext)
      .fontWeight(.bold)
      .foregroundStyle(.secondary)
      .minimumScaleFactor(0.82)
      .accessibilityElement(children: .combine)
   }
}

/// 2人分のアバターを斜めに重ねて、ペア感を出す表示部品。
struct DiagonalOverlappingPersonAvatars: View {
   @Environment(\.colorScheme) private var colorScheme

   let firstPerson: Person
   let secondPerson: Person
   var size: CGFloat
   var horizontalOffset: CGFloat? = nil
   var verticalOffset: CGFloat? = nil
   var showsBackground = false

   var body: some View {
      let xOffset = horizontalOffset ?? size * 0.48
      let yOffset = verticalOffset ?? size * 0.2

      ZStack(alignment: .topLeading) {
         PersonAvatar(person: firstPerson, size: size, showsShadow: false)
            .zIndex(0)

         PersonAvatar(person: secondPerson, size: size, showsShadow: false)
            .overlay {
               Circle()
                  .stroke(overlapBorder, lineWidth: max(1, size * 0.035))
            }
            .offset(x: xOffset, y: yOffset)
            .zIndex(1)
      }
      .frame(
         width: size + xOffset,
         height: size + yOffset,
         alignment: .topLeading
      )
      .padding(showsBackground ? max(4, size * 0.12) : 0)
      .background {
         if showsBackground {
            Capsule()
               .fill(avatarBackground)
         }
      }
      .accessibilityHidden(true)
   }

   private var avatarBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.7)
   }

   private var overlapBorder: Color {
      colorScheme == .dark ? LikehateTheme.surface : .white
   }
}

/// 空状態をカードに閉じ込めず、画面上に直接伝えるための共通View。
struct EmptyMemoStateView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let systemImage: String
   let accent: Color
   let title: String
   let message: String

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      VStack(spacing: 14) {
         Image(systemName: systemImage)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(accent)
            .frame(width: 58, height: 58)
            .background(accent.opacity(0.12), in: Circle())
            .overlay {
               Circle()
                  .stroke(accent.opacity(0.16), lineWidth: 1)
            }
            .accessibilityHidden(true)

         VStack(spacing: 8) {
            Text(verbatim: title)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .multilineTextAlignment(.center)

            Text(verbatim: message)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
               .multilineTextAlignment(.center)
               .lineSpacing(3)
         }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 10)
      .accessibilityElement(children: .combine)
   }
}

/// 好き嫌いのタイトル一覧を、共通カードの質感で表示するView。
struct LikeDislikeListCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let titles: [String]
   let accent: Color

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      AppSectionCard {
         VStack(spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
               Text(verbatim: title)
                  .font(typography.body)
                  .foregroundStyle(.primary)
                  .lineLimit(6)
                  .multilineTextAlignment(.leading)
                  .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)
                  .padding(.horizontal, layout.cardPadding)
                  .padding(.vertical, 4)

               if index < titles.count - 1 {
                  Rectangle()
                     .fill(LikehateTheme.separator)
                     .frame(height: 1)
                     .padding(.horizontal, layout.cardPadding)
               }
            }
         }
         .overlay(alignment: .leading) {
            Rectangle()
               .fill(accent.opacity(0.32))
               .frame(width: 3)
               .clipShape(.rect(cornerRadius: 2))
               .padding(.vertical, 14)
         }
      }
   }
}
