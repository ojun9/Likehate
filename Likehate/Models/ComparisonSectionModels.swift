/// 比較カテゴリ1つ分の表示項目。
struct ComparisonSection: Identifiable, Hashable {
   let category: ComparisonCategory
   let titles: [String]

   var id: ComparisonCategory { category }
}

/// 比較結果画面でカテゴリを「一緒」「避ける」「違い」に束ねる定義。
struct ComparisonResultSectionGroup: Identifiable, Hashable {
   /// 比較結果画面に表示する上位セクション。
   enum GroupID: String, CaseIterable {
      case together
      case avoid
      case differences
   }

   let id: GroupID
   let titleKey: String
   let categories: [ComparisonCategory]

   /// 比較結果画面で表示するグループの並び順。
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

   /// このグループに属する比較セクションだけを抜き出す。
   func sections(from sections: [ComparisonSection]) -> [ComparisonSection] {
      sections.filter { categories.contains($0.category) }
   }
}
