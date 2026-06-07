import SwiftUI

/// 2人の比較結果をカテゴリ別に表示する画面。
struct ComparisonResultView: View {
   @EnvironmentObject private var store: LikeHateStore

   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let sections = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID)
            ScrollView {
               VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                  ComparisonPeopleHeader(firstPerson: firstPerson, secondPerson: secondPerson)

                  ForEach(ComparisonResultSectionGroup.ordered) { group in
                     ComparisonResultGroup(
                        title: LocalizedStringKey(group.titleKey),
                        sections: group.sections(from: sections),
                        firstPerson: firstPerson,
                        secondPerson: secondPerson,
                        firstPersonID: firstPersonID,
                        secondPersonID: secondPersonID
                     )
                  }
               }
               .padding(layout.screenPadding)
            }
            .onAppear {
               FAAnalytics.log(.screenView(.compareResult, parameters: [
                  .firstPersonID: firstPersonID.uuidString,
                  .secondPersonID: secondPersonID.uuidString,
                  .personCount: store.persons.count
               ]))
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle("CompareTitle")
      .navigationBarTitleDisplayMode(.inline)
      .background(LikehateTheme.background)
   }
}
