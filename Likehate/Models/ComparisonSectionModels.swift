struct ComparisonSection: Identifiable, Hashable {
   let category: ComparisonCategory
   let titles: [String]

   var id: ComparisonCategory { category }
}

struct ComparisonResultSectionGroup: Identifiable, Hashable {
   enum GroupID: String, CaseIterable {
      case together
      case avoid
      case differences
   }

   let id: GroupID
   let titleKey: String
   let categories: [ComparisonCategory]

   static let ordered: [ComparisonResultSectionGroup] = [
      ComparisonResultSectionGroup(
         id: .together,
         titleKey: "ComparisonTogetherTitle",
         categories: [.commonLike]
      ),
      ComparisonResultSectionGroup(
         id: .avoid,
         titleKey: "ComparisonAvoidTitle",
         categories: [.commonHate]
      ),
      ComparisonResultSectionGroup(
         id: .differences,
         titleKey: "ComparisonDifferencesTitle",
         categories: [.firstOnlyLike, .secondOnlyLike, .firstOnlyHate, .secondOnlyHate]
      )
   ]

   func sections(from sections: [ComparisonSection]) -> [ComparisonSection] {
      sections.filter { categories.contains($0.category) }
   }
}
