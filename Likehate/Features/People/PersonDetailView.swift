import SwiftUI

/// 1人の好き嫌いを見返し、追加・一覧・比較へ進む人物詳細画面。
struct PersonDetailView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var formMode: PersonFormMode?

   let personID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if let person = store.person(for: personID) {
            ScrollView {
               VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                  HStack(spacing: 16) {
                     PersonAvatar(person: person, size: 83)

                     Text(verbatim: person.displayName)
                        .font(typography.screenTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                  }
                  .padding(.top, 8)

                  PersonEntryPreviewSection(person: person, kind: .like)
                  PersonEntryPreviewSection(person: person, kind: .hate)

                  comparisonLink(for: person)
                     .padding(.top, -(layout.sectionSpacing / 3))
               }
               .padding(.horizontal, layout.screenPadding)
               .padding(.vertical, layout.cardSpacing)
            }
            .background(LikehateTheme.background)
            .navigationTitle(person.displayName)
            .toolbar {
               ToolbarItem(placement: .topBarTrailing) {
                  Button {
                     FAAnalytics.log(.track(.personDetailEditTapped, parameters: personDetailAnalyticsParameters(person: person)))
                     formMode = .edit(person)
                  } label: {
                     Image(systemName: "pencil")
                  }
                  .accessibilityLabel(Text("EditPersonButton"))
               }
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationBarTitleDisplayMode(.inline)
      .sheet(item: $formMode) { formMode in
         NavigationStack {
            PersonFormView(mode: formMode)
         }
      }
      .onAppear {
         var parameters: FAParameters = [
            .personID: personID.uuidString,
            .personCount: store.persons.count,
            .entryCount: store.totalItemCount
         ]
         if let person = store.person(for: personID) {
            parameters[.isMe] = person.isMe
         }
         FAAnalytics.log(.screenView(.personDetail, parameters: parameters))
      }
   }

   @ViewBuilder
   private func comparisonLink(for person: Person) -> some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      if let mePerson = store.mePerson, mePerson.id != person.id {
         NavigationLink {
            ComparisonResultView(firstPersonID: mePerson.id, secondPersonID: person.id)
         } label: {
            HStack {
               Text(verbatim: String.localizedStringWithFormat(String(localized: "CompareWithPersonFormat"), person.displayName))
                  .font(typography.button)
                  .foregroundStyle(.primary)
                  .lineLimit(2)

               Spacer()

               Image(systemName: "chevron.right")
                  .font(typography.subtext)
                  .foregroundStyle(.tertiary)
            }
            .padding(.top, 3)
            .frame(maxWidth: .infinity, minHeight: max(56, layout.rowMinHeight), alignment: .leading)
            .contentShape(Rectangle())
         }
         .buttonStyle(.plain)
         .simultaneousGesture(TapGesture().onEnded {
            FAAnalytics.log(.track(.personDetailCompareTapped, parameters: personDetailAnalyticsParameters(person: person).merging([
               .target: "direct_compare"
            ])))
         })
      } else {
         NavigationLink {
            ComparisonSelectionView()
         } label: {
            HStack {
               Text("CompareWithSomeoneButton")
                  .font(typography.button)
                  .foregroundStyle(.primary)

               Spacer()

               Image(systemName: "chevron.right")
                  .font(typography.subtext)
                  .foregroundStyle(.tertiary)
            }
            .padding(.top, 3)
            .frame(maxWidth: .infinity, minHeight: max(56, layout.rowMinHeight), alignment: .leading)
            .contentShape(Rectangle())
         }
         .buttonStyle(.plain)
         .simultaneousGesture(TapGesture().onEnded {
            FAAnalytics.log(.track(.personDetailCompareTapped, parameters: personDetailAnalyticsParameters(person: person).merging([
               .target: "compare_selection"
            ])))
         })
      }
   }

   private func personDetailAnalyticsParameters(person: Person) -> FAParameters {
      [
         .personID: person.id.uuidString,
         .isMe: person.isMe,
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount
      ]
   }
}
