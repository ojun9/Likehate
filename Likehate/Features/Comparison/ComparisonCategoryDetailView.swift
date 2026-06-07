import SwiftUI

/// 比較結果カテゴリをタップした後の詳細一覧画面。
struct ComparisonCategoryDetailView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let category: ComparisonCategory
   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let section = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID).first { $0.category == category }
            let titles = section?.titles ?? []
            let showsBanner = AdDisplayPolicy(adsRemoved: store.appSettings.adsRemoved, isPremium: store.appSettings.isPremium).showsListAd(hasItems: !titles.isEmpty)

            ScrollView {
               VStack(alignment: .leading, spacing: layout.cardSpacing + 8) {
                  PersonPairHeaderView(firstPerson: firstPerson, secondPerson: secondPerson, avatarSize: ComparisonAvatarMetrics.categorySize)
                     .padding(.top, 24)

                  if titles.isEmpty {
                     EmptyMemoStateView(
                        systemImage: emptyStateIcon,
                        accent: category.kind.color,
                        title: emptyTitle(category: category, firstPerson: firstPerson, secondPerson: secondPerson),
                        message: emptyMessage(category: category, firstPerson: firstPerson, secondPerson: secondPerson)
                     )
                     .padding(.top, 44)
                  } else {
                     VStack(spacing: 0) {
                        LikeDislikeListCard(titles: titles, accent: category.kind.color)

                        if showsBanner {
                           ConditionalListAdBanner(
                              placement: .comparisonCategoryDetail,
                              hasItems: !titles.isEmpty,
                              topPadding: max(12, layout.cardSpacing / 2) + 4,
                              bottomPadding: 20
                           )
                           .frame(maxWidth: .infinity, alignment: .center)
                           .padding(.horizontal, -layout.screenPadding)
                           .onAppear {
                              FAAnalytics.log(.track(.comparisonCategoryAdVisible, parameters: categoryDetailAnalyticsParameters(
                                 firstPerson: firstPerson,
                                 secondPerson: secondPerson,
                                 itemCount: titles.count
                              )))
                           }
                        }
                     }
                  }
               }
               .padding(.horizontal, layout.screenPadding)
               .padding(.bottom, layout.sectionSpacing)
            }
            .background(LikehateTheme.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle(category.title(first: firstPerson, second: secondPerson))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
               FAAnalytics.log(.screenView(.comparisonCategoryDetail, parameters: categoryDetailAnalyticsParameters(
                  firstPerson: firstPerson,
                  secondPerson: secondPerson,
                  itemCount: titles.count
               )))
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
   }

   private var emptyStateIcon: String {
      switch category.kind {
      case .like: return "heart"
      case .hate: return "moon"
      }
   }

   private func emptyTitle(category: ComparisonCategory, firstPerson: Person, secondPerson: Person) -> String {
      switch category {
      case .commonLike:
         return String(localized: "ComparisonEmptyCommonLike")
      case .commonHate:
         return String(localized: "ComparisonEmptyCommonHate")
      case .firstOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptyFirstOnlyLikeFormat"), firstPerson.displayName)
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyLikeFormat"), secondPerson.displayName)
      case .firstOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptyFirstOnlyHateFormat"), firstPerson.displayName)
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyHateFormat"), secondPerson.displayName)
      }
   }

   private func emptyMessage(category: ComparisonCategory, firstPerson: Person, secondPerson: Person) -> String {
      switch category {
      case .commonLike:
         return String(localized: "ComparisonEmptyCommonLikeMessage")
      case .commonHate:
         return String(localized: "ComparisonEmptyCommonHateMessage")
      case .firstOnlyLike:
         return String(localized: "ComparisonEmptyFirstOnlyLikeMessage")
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyLikeMessageFormat"), secondPerson.displayName)
      case .firstOnlyHate:
         return String(localized: "ComparisonEmptyFirstOnlyHateMessage")
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyHateMessageFormat"), secondPerson.displayName)
      }
   }

   private func categoryDetailAnalyticsParameters(firstPerson: Person, secondPerson: Person, itemCount: Int) -> FAParameters {
      [
         .category: category.rawValue,
         .kind: category.kind.rawValue,
         .itemCount: itemCount,
         .isEmpty: itemCount == 0,
         .firstPersonID: firstPerson.id.uuidString,
         .secondPersonID: secondPerson.id.uuidString,
         .firstIsMe: firstPerson.isMe,
         .secondIsMe: secondPerson.isMe,
         .personCount: store.persons.count
      ]
   }
}
