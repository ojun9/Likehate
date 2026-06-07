import SwiftUI

struct PersonEntryPreviewSection: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person
   let kind: EntryKind

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics
      let items = store.items(for: person.id, kind: kind)
      let previewItems = EntryPreviewItems.items(from: items)
      let countText = String.localizedStringWithFormat(String(localized: "ItemsCountFormat"), items.count)

      VStack(alignment: .leading, spacing: 16) {
         HStack {
            Text(verbatim: kind.title(for: person))
               .font(typography.sectionTitle)
            Spacer()
            Text(verbatim: countText)
               .font(typography.count)
               .foregroundStyle(.secondary)
         }

         if previewItems.isEmpty {
            Text(kind.emptyListTitle(for: person))
               .font(typography.body)
               .foregroundStyle(.secondary)
               .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)
         } else {
            VStack(spacing: 0) {
               ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                  Text(verbatim: item.title)
                     .font(typography.body)
                     .lineLimit(2)
                     .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)

                  if index < previewItems.count - 1 {
                     Divider()
                        .overlay(sectionDividerColor)
                        .padding(.vertical, 2)
                  }
               }
            }
         }

         HStack(spacing: 18) {
            NavigationLink {
               WriteItemView(kind: kind, personID: person.id)
            } label: {
               Text(addTitle)
                  .font(typography.button)
                  .foregroundStyle(kind.color)
                  .lineLimit(2)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
               FAAnalytics.log(.track(.personDetailAddEntryTapped, parameters: sectionAnalyticsParameters(itemCount: items.count)))
            })

            if !items.isEmpty {
               NavigationLink {
                  ItemListView(kind: kind, personID: person.id)
               } label: {
                  Text("ViewAllButton")
                     .font(typography.subtext)
                     .foregroundStyle(.secondary)
               }
               .buttonStyle(.plain)
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.personDetailViewAllTapped, parameters: sectionAnalyticsParameters(itemCount: items.count)))
               })
            }

            Spacer(minLength: 0)
         }
         .frame(minHeight: 36)
      }
      .padding(layout.cardPadding)
      .background(sectionBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(kind.color.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
      )
   }

   private var sectionBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : LikehateTheme.surface.opacity(0.78)
   }

   private var sectionDividerColor: Color {
      colorScheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.06)
   }

   private var addTitle: LocalizedStringKey {
      switch (kind, person.isMe) {
      case (.like, _):
         return "AddLikeInlineButton"
      case (.hate, _):
         return "AddHateInlineButton"
      }
   }

   private func sectionAnalyticsParameters(itemCount: Int) -> FAParameters {
      [
         .personID: person.id.uuidString,
         .isMe: person.isMe,
         .kind: kind.rawValue,
         .itemCount: itemCount,
         .personCount: store.persons.count
      ]
   }
}
