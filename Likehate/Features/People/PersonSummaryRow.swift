import SwiftUI

/// 人物選択画面で使う、人物の概要を1行で表示する行View。
struct PersonSummaryRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let likeCount = store.items(for: person.id, kind: .like).count
      let hateCount = store.items(for: person.id, kind: .hate).count
      let countFormat = String(localized: "PersonCountFormat")
      let countText = String.localizedStringWithFormat(countFormat, likeCount, hateCount)

      HStack(spacing: 12) {
         PersonAvatar(person: person)

         VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
               Text(verbatim: person.displayName)
                  .font(typography.body)
                  .foregroundStyle(.primary)
                  .lineLimit(1)
            }

            Text(verbatim: countText)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
         }
      }
      .padding(.vertical, 5)
      .accessibilityElement(children: .combine)
   }
}
