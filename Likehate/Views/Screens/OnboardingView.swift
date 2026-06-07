import SwiftUI

/// オンボーディングがどの導線から表示されたか。
enum OnboardingPresentationSource: String, Identifiable {
   case automatic
   case debug

   var id: String { rawValue }
}

/// 初回ユーザーにLikehateの最初の価値を伝えるオンボーディング画面。
struct OnboardingView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var selectedPage = OnboardingPage.write.rawValue

   let source: OnboardingPresentationSource
   let onComplete: () -> Void

   init(source: OnboardingPresentationSource = .automatic, onComplete: @escaping () -> Void = {}) {
      self.source = source
      self.onComplete = onComplete
   }

   var body: some View {
      let layout = store.layoutMetrics

      ZStack {
         LikehateTheme.background
            .ignoresSafeArea()

         LikehateFloatingBackgroundView(
            blurPlacement: .full,
            isAnimationEnabled: store.animationEnabled
         )

         VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
               ForEach(OnboardingPage.allCases) { page in
                  OnboardingPageView(page: page)
                     .tag(page.rawValue)
               }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 18) {
               OnboardingPageIndicator(selectedPage: selectedPage)

               Button {
                  advanceOrComplete()
               } label: {
                  Text(isLastPage ? "OnboardingStartButton" : "OnboardingNextButton")
                     .font(store.typography(for: dynamicTypeSize).button)
                     .lineLimit(1)
                     .minimumScaleFactor(0.75)
                     .frame(maxWidth: .infinity)
                     .frame(minHeight: 54)
               }
               .buttonStyle(.borderedProminent)
               .tint(currentPage.accentColor)
               .clipShape(Capsule())
            }
            .padding(.horizontal, layout.screenPadding)
            .padding(.bottom, max(24, layout.screenPadding))
         }
      }
      .navigationTitle("OnboardingNavigationTitle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            Button("OnboardingSkipButton") {
               close(action: "skip")
            }
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.onboarding, parameters: analyticsParameters(action: "appear")))
      }
   }

   private var currentPage: OnboardingPage {
      OnboardingPage(rawValue: selectedPage) ?? .write
   }

   private var isLastPage: Bool {
      selectedPage == OnboardingPage.allCases.count - 1
   }

   private func advanceOrComplete() {
      if isLastPage {
         close(action: "complete")
      } else {
         let previousPage = selectedPage
         withAnimation(.easeInOut(duration: 0.22)) {
            selectedPage += 1
         }
         FAAnalytics.log(.track(.onboardingNextTapped, parameters: analyticsParameters(action: "next", page: previousPage)))
         HapticsClient.light()
      }
   }

   private func close(action: String) {
      switch action {
      case "skip":
         FAAnalytics.log(.track(.onboardingSkipped, parameters: analyticsParameters(action: action)))
         HapticsClient.light()
      default:
         FAAnalytics.log(.track(.onboardingCompleted, parameters: analyticsParameters(action: action)))
         HapticsClient.success()
      }

      onComplete()
      dismiss()
   }

   private func analyticsParameters(action: String, page: Int? = nil) -> FAParameters {
      [
         .source: source.rawValue,
         .target: action,
         .count: (page ?? selectedPage) + 1,
         .totalCount: OnboardingPage.allCases.count,
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .animationEnabled: store.animationEnabled,
         .textSize: store.textSize.rawValue
      ]
   }
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
   case write
   case people
   case compare

   var id: Int { rawValue }

   var title: LocalizedStringKey {
      switch self {
      case .write: return "OnboardingWriteTitle"
      case .people: return "OnboardingPeopleTitle"
      case .compare: return "OnboardingCompareTitle"
      }
   }

   var message: LocalizedStringKey {
      switch self {
      case .write: return "OnboardingWriteMessage"
      case .people: return "OnboardingPeopleMessage"
      case .compare: return "OnboardingCompareMessage"
      }
   }

   var systemImageName: String {
      switch self {
      case .write: return "heart.circle.fill"
      case .people: return "person.2.fill"
      case .compare: return "arrow.left.arrow.right.circle.fill"
      }
   }

   var accentColor: Color {
      switch self {
      case .write: return LikehateTheme.likeAccent
      case .people: return LikehateTheme.sparkleAccent
      case .compare: return LikehateTheme.hateAccent
      }
   }
}

private struct OnboardingPageView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let page: OnboardingPage

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      ScrollView {
         VStack(spacing: 24) {
            Image(systemName: page.systemImageName)
               .font(.system(size: 54, weight: .bold, design: .rounded))
               .foregroundStyle(.white)
               .frame(width: 104, height: 104)
               .background(page.accentColor, in: Circle())
               .shadow(color: page.accentColor.opacity(0.26), radius: 18, x: 0, y: 10)
               .accessibilityHidden(true)

            VStack(spacing: 12) {
               Text(page.title)
                  .font(typography.screenTitle)
                  .foregroundStyle(.primary)
                  .multilineTextAlignment(.center)
                  .fixedSize(horizontal: false, vertical: true)

               Text(page.message)
                  .font(typography.bodyRegular)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
                  .lineSpacing(4)
                  .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 440)

            OnboardingPreviewCard(page: page)
               .frame(maxWidth: 420)
         }
         .padding(.horizontal, layout.screenPadding)
         .padding(.top, max(36, layout.sectionSpacing))
         .padding(.bottom, layout.sectionSpacing)
         .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
   }
}

private struct OnboardingPreviewCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let page: OnboardingPage

   var body: some View {
      let layout = store.layoutMetrics

      VStack(spacing: 12) {
         switch page {
         case .write:
            OnboardingPreviewRow(iconName: "heart.fill", title: "Like", color: LikehateTheme.likeAccent)
            OnboardingPreviewRow(iconName: "hand.thumbsdown.fill", title: "Hate", color: LikehateTheme.hateAccent)
         case .people:
            OnboardingPeoplePreview()
         case .compare:
            OnboardingPreviewRow(iconName: "heart.fill", title: "ComparisonCommonLike", color: LikehateTheme.likeAccent)
            OnboardingPreviewRow(iconName: "rectangle.split.2x1.fill", title: "ComparisonDifferencesTitle", color: LikehateTheme.sparkleAccent)
         }
      }
      .padding(layout.cardPadding)
      .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
         RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(LikehateTheme.border.opacity(0.72), lineWidth: 1)
      }
      .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 12, x: 0, y: 5)
      .accessibilityElement(children: .combine)
   }

   private var cardBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.06) : LikehateTheme.surface.opacity(0.94)
   }
}

private struct OnboardingPreviewRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let iconName: String
   let title: LocalizedStringKey
   let color: Color

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(spacing: 12) {
         Image(systemName: iconName)
            .font(typography.body)
            .foregroundStyle(color)
            .frame(width: 28, height: 28)

         Text(title)
            .font(typography.body)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(LikehateTheme.tintFill(color, scheme: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
   }
}

private struct OnboardingPeoplePreview: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)

      HStack(spacing: 12) {
         OnboardingPersonPill(systemImageName: "person.crop.circle.fill", title: "DefaultMeName", color: LikehateTheme.likeAccent)
         OnboardingPersonPill(systemImageName: "person.crop.circle.badge.plus", title: "AddPersonButton", color: LikehateTheme.hateAccent)
      }
      .font(typography.body)
   }
}

private struct OnboardingPersonPill: View {
   @Environment(\.colorScheme) private var colorScheme

   let systemImageName: String
   let title: LocalizedStringKey
   let color: Color

   var body: some View {
      VStack(spacing: 8) {
         Image(systemName: systemImageName)
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .foregroundStyle(color)

         Text(title)
            .font(.callout.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 112)
      .padding(.horizontal, 8)
      .background(LikehateTheme.tintFill(color, scheme: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
   }
}

private struct OnboardingPageIndicator: View {
   let selectedPage: Int

   var body: some View {
      HStack(spacing: 8) {
         ForEach(OnboardingPage.allCases) { page in
            Capsule()
               .fill(page.rawValue == selectedPage ? page.accentColor : Color.secondary.opacity(0.24))
               .frame(width: page.rawValue == selectedPage ? 26 : 8, height: 8)
         }
      }
      .frame(height: 12)
      .animation(.easeInOut(duration: 0.22), value: selectedPage)
      .accessibilityLabel(Text(verbatim: pageIndicatorAccessibilityText))
   }

   private var pageIndicatorAccessibilityText: String {
      String.localizedStringWithFormat(
         String(localized: "OnboardingPageIndicatorFormat"),
         selectedPage + 1,
         OnboardingPage.allCases.count
      )
   }
}
