import SwiftUI

/// アプリ全体のNavigationStackを保持するルートView。
struct RootView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var onboardingSource: OnboardingPresentationSource?

   var body: some View {
      NavigationStack {
         HomeView { source in
            onboardingSource = source
         }
      }
      .fullScreenCover(item: $onboardingSource) { source in
         NavigationStack {
            OnboardingView(source: source) {
               if source == .automatic {
                  store.completeOnboarding()
               }
            }
         }
         .interactiveDismissDisabled()
      }
      .onAppear {
         presentOnboardingIfNeeded()
      }
      .onChange(of: store.shouldPresentOnboarding) {
         presentOnboardingIfNeeded()
      }
   }

   private func presentOnboardingIfNeeded() {
      guard store.shouldPresentOnboarding else { return }
      onboardingSource = .automatic
   }
}

/// 人物一覧、追加導線、比較導線を表示するホーム画面。
struct HomeView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var isShowingSettings = false
   @State private var isShowingAddPerson = false
   @State private var isShowingPremium = false
   @State private var showsDebugOnboardingAfterSettingsDismiss = false
   @State private var pendingAddedPerson: PersonDetailRoute?
   @State private var selectedPersonRoute: PersonDetailRoute?

   let onOpenOnboarding: (OnboardingPresentationSource) -> Void

   init(onOpenOnboarding: @escaping (OnboardingPresentationSource) -> Void = { _ in }) {
      self.onOpenOnboarding = onOpenOnboarding
   }

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      ScrollView {
         VStack(alignment: .leading, spacing: layout.cardSpacing) {
            Text("HomePeopleSectionTitle")
               .font(typography.sectionTitle)
               .padding(.top, 22)

            VStack(spacing: layout.cardSpacing) {
               ForEach(store.persons) { person in
                  NavigationLink {
                     PersonDetailView(personID: person.id)
                  } label: {
                     HomePersonCard(person: person)
                  }
                  .buttonStyle(.plain)
                  .simultaneousGesture(TapGesture().onEnded {
                     FAAnalytics.log(.track(.homePersonTapped, parameters: personAnalyticsParameters(person)))
                  })
               }
            }

            if store.persons.filter({ !$0.isMe }).isEmpty {
               Text("HomeAddPeopleHint")
                  .font(typography.subtext)
                  .foregroundStyle(.secondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, 4)
            }

            Button {
               FAAnalytics.log(.track(.homeAddPersonTapped, parameters: homeAnalyticsParameters))
               showAddPersonOrPremium()
            } label: {
               Label("AddPersonButton", systemImage: "plus")
                  .font(typography.button)
                  .foregroundStyle(LikehateTheme.likeAccent)
                  .frame(minHeight: 48)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .padding(.vertical, 2)

            if store.persons.count > 1 {
               NavigationLink {
                  ComparisonSelectionView()
               } label: {
                  VStack(alignment: .leading, spacing: 3) {
                     Text("HomeCompareTitle")
                        .font(typography.button)
                        .foregroundStyle(.primary)

                     Text("HomeCompareSubtitle")
                        .font(typography.subtext)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                  }
                  .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                  .padding(.horizontal, 18)
                  .padding(.vertical, 12)
                  .background(compareBackground, in: Capsule())
                  .overlay(
                     Capsule()
                        .stroke(LikehateTheme.border.opacity(0.65), lineWidth: 1)
                  )
               }
               .buttonStyle(.plain)
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.homeCompareTapped, parameters: homeAnalyticsParameters))
               })
            } else {
               Text("HomeCompareDisabledHint")
                  .font(typography.subtext)
                  .foregroundStyle(.secondary)
                  .padding(.leading, 4)
                  .padding(.top, 2)
            }
         }
         .padding(.horizontal, layout.screenPadding)
         .padding(.bottom, layout.sectionSpacing)
      }
      .background(LikehateTheme.background.ignoresSafeArea())
      .navigationTitle("AppTitle")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedPersonRoute) { route in
         PersonDetailView(personID: route.id)
      }
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            Button {
               FAAnalytics.log(.track(.settingsOpenedFromHome, parameters: homeAnalyticsParameters))
               isShowingSettings = true
            } label: {
               Image(systemName: "gearshape")
            }
            .accessibilityLabel(Text("SettingsTitle"))
         }
      }
      .alert(item: $store.purchaseMessage) { message in
         Alert(
            title: Text(message.title),
            message: Text(message.message),
            dismissButton: .default(Text("OK"))
         )
      }
      .alert(item: $store.reviewPrompt) { prompt in
         Alert(
            title: Text(prompt.title),
            message: Text(prompt.message),
            primaryButton: .default(Text("ThankYou")) {
               FAAnalytics.log(.track(.reviewPromptConfirmed, parameters: [
                  .screen: FAScreen.home.rawValue
               ]))
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               FAAnalytics.log(.track(.reviewPromptCancelled, parameters: [
                  .screen: FAScreen.home.rawValue
               ]))
            }
         )
      }
      .sheet(isPresented: $isShowingSettings, onDismiss: showDebugOnboardingIfNeeded) {
         NavigationStack {
            SettingsView {
               showsDebugOnboardingAfterSettingsDismiss = true
               isShowingSettings = false
            }
         }
      }
      .sheet(isPresented: $isShowingAddPerson, onDismiss: showAddedPersonIfNeeded) {
         NavigationStack {
            PersonFormView(mode: .add) { person in
               pendingAddedPerson = PersonDetailRoute(id: person.id)
            }
         }
      }
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.home, parameters: homeAnalyticsParameters))
      }
   }

   private func showAddedPersonIfNeeded() {
      guard let pendingAddedPerson else { return }
      self.pendingAddedPerson = nil
      selectedPersonRoute = pendingAddedPerson
   }

   private func showDebugOnboardingIfNeeded() {
      guard showsDebugOnboardingAfterSettingsDismiss else { return }
      showsDebugOnboardingAfterSettingsDismiss = false
      onOpenOnboarding(.debug)
   }

   private func showAddPersonOrPremium() {
      if store.canAddPerson {
         isShowingAddPerson = true
      } else {
         FAAnalytics.log(.track(.homePremiumGateShown, parameters: homeAnalyticsParameters.merging([
            .reason: "person_limit"
         ])))
         isShowingPremium = true
      }
   }

   private var homeAnalyticsParameters: FAParameters {
      [
         .likeCount: store.likes.count,
         .hateCount: store.hates.count,
         .entryCount: store.totalItemCount,
         .personCount: store.persons.count,
         .totalCount: store.likes.count + store.hates.count,
         .didBuyRemoveAd: store.didBuyRemoveAd,
         .didBuyPremium: store.didBuyPremium,
         .animationEnabled: store.animationEnabled
      ]
   }

   private func personAnalyticsParameters(_ person: Person) -> FAParameters {
      homeAnalyticsParameters.merging([
         .personID: person.id.uuidString,
         .isMe: person.isMe
      ])
   }

   private var compareBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.045) : LikehateTheme.surface.opacity(0.72)
   }
}

/// ホームから人物詳細へ遷移するための識別子。
struct PersonDetailRoute: Identifiable, Hashable {
   let id: UUID
}

/// ホーム上で人物のアバター、呼び方、登録件数を表示するカード。
private struct HomePersonCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics
      let likeCount = store.items(for: person.id, kind: .like).count
      let hateCount = store.items(for: person.id, kind: .hate).count
      let likeCountText = String.localizedStringWithFormat(String(localized: "LikeCountFormat"), likeCount)
      let hateCountText = String.localizedStringWithFormat(String(localized: "HateCountFormat"), hateCount)

      HStack(spacing: 18) {
         PersonAvatar(person: person, size: layout.homePersonAvatarSize, showsShadow: false)

         VStack(alignment: .leading, spacing: 9) {
            Text(verbatim: person.displayName)
               .font(typography.sectionTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)

            VStack(alignment: .leading, spacing: 4) {
               Text(verbatim: likeCountText)
                  .foregroundStyle(LikehateTheme.likeAccent)

               Text(verbatim: hateCountText)
                  .foregroundStyle(LikehateTheme.hateAccent)
            }
            .font(typography.subtext)
            .lineLimit(1)
         }

         Spacer(minLength: 8)

         Image(systemName: "chevron.right")
            .font(typography.subtext)
            .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, max(18, layout.cardPadding - 2))
      .frame(maxWidth: .infinity, minHeight: layout.personCardMinHeight, alignment: .leading)
      .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(LikehateTheme.border.opacity(0.72), lineWidth: 1)
      )
      .shadow(color: LikehateTheme.cardShadow(for: colorScheme).opacity(0.78), radius: colorScheme == .dark ? 9 : 7, x: 0, y: 3)
      .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .accessibilityElement(children: .combine)
   }

   private var cardBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.06) : LikehateTheme.surface
   }
}
