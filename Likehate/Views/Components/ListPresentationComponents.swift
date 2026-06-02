import SwiftUI

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

struct PersonPairHeaderView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPerson: Person
   let secondPerson: Person
   var avatarSize: CGFloat = 42

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(spacing: avatarSize >= 40 ? 10 : 8) {
         PersonAvatar(person: firstPerson, size: avatarSize)
            .accessibilityHidden(true)

         Text(verbatim: firstPerson.displayName)
            .lineLimit(1)

         Text("PersonPairSeparator")
            .foregroundStyle(.tertiary)

         PersonAvatar(person: secondPerson, size: avatarSize)
            .accessibilityHidden(true)

         Text(verbatim: secondPerson.displayName)
            .lineLimit(1)
      }
      .font(typography.subtext)
      .fontWeight(.bold)
      .foregroundStyle(.secondary)
      .minimumScaleFactor(0.82)
      .accessibilityElement(children: .combine)
   }
}

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
