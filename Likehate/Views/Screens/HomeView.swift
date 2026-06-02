import FirebaseAnalytics
import SwiftUI

struct RootView: View {
   var body: some View {
      NavigationStack {
         HomeView()
      }
   }
}

struct HomeView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var isShowingSettings = false
   @State private var isShowingAddPerson = false
   @State private var pendingAddedPerson: PersonDetailRoute?
   @State private var selectedPersonRoute: PersonDetailRoute?

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      ScrollView {
         VStack(alignment: .leading, spacing: layout.cardSpacing) {
            if store.animationEnabled {
               LottieLoopView(name: "KiraKira")
                 .frame(height: 64)
                  .frame(maxWidth: .infinity)
                  .opacity(colorScheme == .dark ? 0.34 : 0.24)
                  .clipped()
                  .padding(.top, 8)
                  .accessibilityHidden(true)
            }

            Text("HomePeopleSectionTitle")
               .font(typography.sectionTitle)
               .padding(.top, store.animationEnabled ? 2 : 22)

            VStack(spacing: layout.cardSpacing) {
               ForEach(store.persons) { person in
                  NavigationLink {
                     PersonDetailView(personID: person.id)
                  } label: {
                     HomePersonCard(person: person)
                  }
                  .buttonStyle(.plain)
                  .simultaneousGesture(TapGesture().onEnded {
                     Analytics.logEvent("home_person_tapped", parameters: personAnalyticsParameters(person))
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
               Analytics.logEvent("home_add_person_tapped", parameters: homeAnalyticsParameters)
               isShowingAddPerson = true
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
                  Analytics.logEvent("home_compare_tapped", parameters: homeAnalyticsParameters)
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
               Analytics.logEvent("settings_opened_from_home", parameters: homeAnalyticsParameters)
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
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               Analytics.logEvent("UserTap_OhThanks...For100", parameters: nil)
            }
         )
      }
      .sheet(isPresented: $isShowingSettings) {
         NavigationStack {
            SettingsView()
         }
      }
      .sheet(isPresented: $isShowingAddPerson, onDismiss: showAddedPersonIfNeeded) {
         NavigationStack {
            PersonFormView(mode: .add) { person in
               pendingAddedPerson = PersonDetailRoute(id: person.id)
            }
         }
      }
      .onAppear {
         Analytics.logEvent("showSwiftUIHome", parameters: homeAnalyticsParameters)
         Analytics.logEvent("screen_view_home", parameters: homeAnalyticsParameters)
      }
   }

   private func showAddedPersonIfNeeded() {
      guard let pendingAddedPerson else { return }
      self.pendingAddedPerson = nil
      selectedPersonRoute = pendingAddedPerson
   }

   private var homeAnalyticsParameters: [String: Any] {
      [
         "like_count": store.likes.count,
         "hate_count": store.hates.count,
         "entry_count": store.totalItemCount,
         "person_count": store.persons.count,
         "total_count": store.likes.count + store.hates.count,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "animation_enabled": store.animationEnabled
      ]
   }

   private func personAnalyticsParameters(_ person: Person) -> [String: Any] {
      homeAnalyticsParameters.merging([
         "person_id": person.id.uuidString,
         "is_me": person.isMe
      ]) { _, new in new }
   }

   private var compareBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.045) : LikehateTheme.surface.opacity(0.72)
   }
}

struct PersonDetailRoute: Identifiable, Hashable {
   let id: UUID
}

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
