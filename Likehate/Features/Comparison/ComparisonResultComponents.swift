import SwiftUI

struct ComparisonPeopleHeader: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(alignment: .center, spacing: 16) {
         DiagonalOverlappingPersonAvatars(
            firstPerson: firstPerson,
            secondPerson: secondPerson,
            size: ComparisonAvatarMetrics.headerSize,
            horizontalOffset: ComparisonAvatarMetrics.headerOverlapOffset,
            verticalOffset: ComparisonAvatarMetrics.headerDiagonalOffset
         )

         HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(verbatim: firstPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.leading)

            Text("ComparisonSeparatorAnd")
               .font(typography.body)
               .foregroundStyle(.secondary)
               .fixedSize(horizontal: true, vertical: false)

            Text(verbatim: secondPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.leading)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .layoutPriority(1)
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, minHeight: max(68, layout.rowMinHeight + 8), alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: comparisonAccessibilityLabel))
   }

   private var comparisonAccessibilityLabel: String {
      String.localizedStringWithFormat(
         String(localized: "ComparisonSubtitleFormat"),
         firstPerson.displayName,
         secondPerson.displayName
      )
   }
}

enum ComparisonAvatarMetrics {
   static let headerSize: CGFloat = 53
   static let headerOverlapOffset: CGFloat = 26
   static let headerDiagonalOffset: CGFloat = 10
   static let categorySize: CGFloat = 42
   static let categoryOverlapOffset: CGFloat = 25
   static let categoryDiagonalOffset: CGFloat = 8
}

struct ComparisonResultGroup: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: LocalizedStringKey
   let sections: [ComparisonSection]
   let firstPerson: Person
   let secondPerson: Person
   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      VStack(alignment: .leading, spacing: 12) {
         Text(title)
            .font(typography.cardTitle)
            .foregroundStyle(.primary)
            .padding(.horizontal, 2)

         VStack(spacing: max(12, layout.cardSpacing - 4)) {
            ForEach(sections) { section in
               NavigationLink {
                  ComparisonCategoryDetailView(
                     category: section.category,
                     firstPersonID: firstPersonID,
                     secondPersonID: secondPersonID
                  )
               } label: {
                  ComparisonCard(
                     title: section.category.title(first: firstPerson, second: secondPerson),
                     count: section.titles.count,
                     category: section.category,
                     firstPerson: firstPerson,
                     secondPerson: secondPerson
                  )
               }
               .buttonStyle(.plain)
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.comparisonCategoryTapped, parameters: [
                     .category: section.category.rawValue,
                     .kind: section.category.kind.rawValue,
                     .itemCount: section.titles.count,
                     .firstPersonID: firstPersonID.uuidString,
                     .secondPersonID: secondPersonID.uuidString
                  ]))
               })
            }
         }
      }
   }
}

private struct ComparisonCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: String
   let count: Int
   let category: ComparisonCategory
   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         Capsule()
            .fill(category.kind.color.opacity(colorScheme == .dark ? 0.78 : 0.64))
            .frame(width: 3, height: ComparisonAvatarMetrics.categorySize)

         ComparisonCategoryAvatar(
            category: category,
            firstPerson: firstPerson,
            secondPerson: secondPerson
         )

         Text(verbatim: title)
            .font(typography.body)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

         Spacer(minLength: 8)

         Text(verbatim: String.localizedStringWithFormat(String(localized: "ItemsCountFormat"), count))
            .font(typography.subtext)
            .foregroundStyle(.secondary)
            .frame(minWidth: 48, alignment: .trailing)
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity, minHeight: max(82, layout.rowMinHeight + 18), alignment: .leading)
      .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(category.kind.color.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
      )
      .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
   }

   private var cardBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.05) : LikehateTheme.surface.opacity(0.8)
   }
}

private struct ComparisonCategoryAvatar: View {
   let category: ComparisonCategory
   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      switch category {
      case .commonLike, .commonHate:
         DiagonalOverlappingPersonAvatars(
            firstPerson: firstPerson,
            secondPerson: secondPerson,
            size: ComparisonAvatarMetrics.categorySize,
            horizontalOffset: ComparisonAvatarMetrics.categoryOverlapOffset,
            verticalOffset: ComparisonAvatarMetrics.categoryDiagonalOffset,
            showsBackground: true
         )
      case .firstOnlyLike, .firstOnlyHate:
         PersonAvatar(person: firstPerson, size: ComparisonAvatarMetrics.categorySize)
            .frame(width: ComparisonAvatarMetrics.categorySize, alignment: .leading)
            .accessibilityHidden(true)
      case .secondOnlyLike, .secondOnlyHate:
         PersonAvatar(person: secondPerson, size: ComparisonAvatarMetrics.categorySize)
            .frame(width: ComparisonAvatarMetrics.categorySize, alignment: .leading)
            .accessibilityHidden(true)
      }
   }
}
