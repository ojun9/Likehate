import SwiftUI

/// ホーム上で人物のアバター、呼び方、登録件数を表示するカード。
struct HomePersonCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics
      let likeCount = store.items(for: person.id, kind: .like).count
      let hateCount = store.items(for: person.id, kind: .hate).count
      let likeCountText = String.localizedStringWithFormat(String(localized: "LikeCountFormat"), likeCount)
      let hateCountText = String.localizedStringWithFormat(String(localized: "HateCountFormat"), hateCount)

      HStack(spacing: 18) {
         PersonAvatar(person: person, size: layout.homePersonAvatarSize, showsShadow: false)

         VStack(alignment: .leading, spacing: 9) {
            Text(verbatim: person.displayName)
               .font(typography.sectionTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)

            VStack(alignment: .leading, spacing: 4) {
               Text(verbatim: likeCountText)
                  .foregroundStyle(LikehateTheme.likeAccent)

               Text(verbatim: hateCountText)
                  .foregroundStyle(LikehateTheme.hateAccent)
            }
            .font(typography.subtext)
            .lineLimit(1)
         }

         Spacer(minLength: 8)

         Image(systemName: "chevron.right")
            .font(typography.subtext)
            .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, max(18, layout.cardPadding - 2))
      .frame(maxWidth: .infinity, minHeight: layout.personCardMinHeight, alignment: .leading)
      .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(LikehateTheme.border.opacity(0.72), lineWidth: 1)
      )
      .shadow(color: LikehateTheme.cardShadow(for: colorScheme).opacity(0.78), radius: colorScheme == .dark ? 9 : 7, x: 0, y: 3)
      .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .accessibilityElement(children: .combine)
   }

   private var cardBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.06) : LikehateTheme.surface
   }
}
