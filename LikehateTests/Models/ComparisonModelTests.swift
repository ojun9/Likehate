import Foundation
import Testing
@testable import Likehate

struct ComparisonCategoryTests {
   @Test("比較カテゴリは入力種別ごとに分かれる")
   func categoriesArePartitionedByEntryKind() {
      let likeCategories = ComparisonCategory.allCases.filter { $0.kind == .like }
      let hateCategories = ComparisonCategory.allCases.filter { $0.kind == .hate }

      #expect(likeCategories == [.firstOnlyLike, .commonLike, .secondOnlyLike])
      #expect(hateCategories == [.firstOnlyHate, .commonHate, .secondOnlyHate])
      #expect(Set(likeCategories + hateCategories) == Set(ComparisonCategory.allCases))
   }

   @Test("人物別の比較タイトルは表示名を使う")
   func personSpecificTitlesUseDisplayNames() {
      let me = makePerson(name: "自分", isMe: true)
      let friend = makePerson(name: "太郎", isMe: false)

      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains(me.displayName))
      #expect(ComparisonCategory.secondOnlyHate.title(first: me, second: friend).contains(friend.displayName))
      #expect(ComparisonCategory.firstOnlyLike.title(first: me, second: friend).contains("自分") == false)
   }
}

struct ComparisonResultSectionGroupTests {
   @Test("比較結果グループだけが最上位セクションになる")
   func resultGroupsAreTheOnlyTopLevelSections() {
      let groups = ComparisonResultSectionGroup.ordered

      #expect(groups.map(\.titleKey) == [
         "ComparisonTogetherTitle",
         "ComparisonAvoidTitle",
         "ComparisonDifferencesTitle"
      ])
      #expect(groups.map(\.id) == [.together, .avoid, .differences])
      #expect(groups.contains { $0.titleKey.hasPrefix("ComparisonSummary") } == false)
   }

   @Test("比較結果グループは全カテゴリを一度ずつ網羅する")
   func resultGroupsCoverEveryCategoryOnce() {
      let categories = ComparisonResultSectionGroup.ordered.flatMap(\.categories)

      #expect(categories.count == ComparisonCategory.allCases.count)
      #expect(Set(categories) == Set(ComparisonCategory.allCases))
   }

   @Test("比較結果グループは自分のセクションだけを絞り込む")
   func resultGroupsFilterTheirOwnSections() throws {
      let sections = ComparisonCategory.allCases.map { category in
         ComparisonSection(category: category, titles: [category.rawValue])
      }
      let together = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .together })
      let avoid = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .avoid })
      let differences = try #require(ComparisonResultSectionGroup.ordered.first { $0.id == .differences })

      #expect(together.sections(from: sections).map(\.category) == [.commonLike])
      #expect(avoid.sections(from: sections).map(\.category) == [.commonHate])
      #expect(differences.sections(from: sections).map(\.category) == [.firstOnlyLike, .secondOnlyLike, .firstOnlyHate, .secondOnlyHate])
   }
}
