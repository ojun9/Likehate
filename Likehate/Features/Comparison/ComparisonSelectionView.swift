import SwiftUI

/// 比較する2人を選ぶ画面。
struct ComparisonSelectionView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var firstPersonID: UUID?
   @State private var secondPersonID: UUID?
   @State private var formMode: PersonFormMode?
   @State private var isShowingPremium = false

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if store.persons.count < 2 {
            comparisonEmptyState(typography: typography, layout: layout)
         } else {
            ScrollView {
               VStack(alignment: .leading, spacing: layout.cardSpacing) {
                  VStack(alignment: .leading, spacing: layout.cardSpacing) {
                     VStack(alignment: .leading, spacing: 8) {
                        Text("CompareFirstPersonTitle")
                           .font(typography.subtext)
                           .foregroundStyle(.secondary)

                        personMenu(selection: $firstPersonID, typography: typography)
                     }

                     Divider()
                        .overlay(LikehateTheme.separator)

                     VStack(alignment: .leading, spacing: 8) {
                        Text("CompareSecondPersonTitle")
                           .font(typography.subtext)
                           .foregroundStyle(.secondary)

                        personMenu(selection: $secondPersonID, typography: typography)
                     }
                  }
                  .padding(layout.cardPadding)
                  .background(LikehateTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                  .overlay(
                     RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(LikehateTheme.border, lineWidth: 1)
                  )
                  .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 12, x: 0, y: 4)

                  if let firstPersonID, let secondPersonID, firstPersonID != secondPersonID {
                     NavigationLink {
                        ComparisonResultView(firstPersonID: firstPersonID, secondPersonID: secondPersonID)
                     } label: {
                        Text("CompareButton")
                           .font(typography.button)
                           .frame(maxWidth: .infinity)
                           .frame(minHeight: 56)
                     }
                     .buttonStyle(.borderedProminent)
                     .tint(EntryKind.hate.color)
                     .simultaneousGesture(TapGesture().onEnded {
                        FAAnalytics.log(.track(.compareSelectionSubmitTapped, parameters: comparisonSelectionAnalyticsParameters.merging([
                           .firstPersonID: firstPersonID.uuidString,
                           .secondPersonID: secondPersonID.uuidString
                        ])))
                     })
                  } else {
                     Text("CompareSamePersonMessage")
                        .font(typography.subtext)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)
                  }
               }
               .padding(layout.screenPadding)
            }
            .background(LikehateTheme.background)
         }
      }
      .navigationTitle("CompareTitle")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(item: $formMode) { formMode in
         NavigationStack {
            PersonFormView(mode: formMode)
         }
      }
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .onAppear {
         normalizeSelection()
         FAAnalytics.log(.screenView(.compareSelection, parameters: comparisonSelectionAnalyticsParameters))
      }
      .onChange(of: store.persons) {
         normalizeSelection()
      }
   }

   private func comparisonEmptyState(typography: AppTypography, layout: AppLayoutMetrics) -> some View {
      ZStack {
         LikehateTheme.background
            .ignoresSafeArea()

         GeometryReader { proxy in
            ScrollView {
               VStack(spacing: layout.cardSpacing) {
                  EmptyMemoStateView(
                     systemImage: "person.2",
                     accent: LikehateTheme.likeAccent,
                     title: String(localized: "CompareEmptyTitle"),
                     message: String(localized: "CompareEmptyMessage")
                  )

                  Button {
                     FAAnalytics.log(.track(.compareSelectionAddPersonTapped, parameters: comparisonSelectionAnalyticsParameters))
                     showAddPersonOrPremium()
                  } label: {
                     Label("AddPersonButton", systemImage: "plus")
                        .font(typography.button)
                        .foregroundStyle(LikehateTheme.likeAccent)
                        .frame(minHeight: 48)
                  }
                  .buttonStyle(.plain)
               }
               .frame(maxWidth: .infinity)
               .frame(minHeight: proxy.size.height, alignment: .center)
               .padding(.horizontal, layout.screenPadding)
               .padding(.vertical, layout.sectionSpacing)
               .offset(y: -24)
            }
         }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
   }

   private func normalizeSelection() {
      let personIDs = Set(store.persons.map(\.id))
      if firstPersonID == nil || !personIDs.contains(firstPersonID!) {
         firstPersonID = store.mePerson?.id ?? store.persons.first?.id
      }

      if secondPersonID == nil || !personIDs.contains(secondPersonID!) || secondPersonID == firstPersonID {
         secondPersonID = store.persons.first { $0.id != firstPersonID }?.id
      }
   }

   private func personMenu(selection: Binding<UUID?>, typography: AppTypography) -> some View {
      Menu {
         ForEach(store.persons) { person in
            Button {
               selection.wrappedValue = person.id
               FAAnalytics.log(.track(.compareSelectionPersonChanged, parameters: comparisonSelectionAnalyticsParameters.merging([
                  .selectedPersonID: person.id.uuidString,
                  .isMe: person.isMe
               ])))
            } label: {
               Text(verbatim: person.displayName)
            }
         }
      } label: {
         if let selectedPerson = selectedPerson(for: selection.wrappedValue) {
            HStack(spacing: 12) {
               PersonAvatar(person: selectedPerson, size: 44, showsShadow: false)

               Text(verbatim: selectedPerson.displayName)
                  .font(typography.cardTitle)
                  .foregroundStyle(selectionTextColor)
                  .fontWeight(.bold)
                  .lineLimit(1)

               Spacer(minLength: 8)

               Image(systemName: "chevron.down")
                  .font(typography.subtext)
                  .fontWeight(.bold)
                  .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
         }
      }
      .buttonStyle(.plain)
   }

   private func selectedPerson(for personID: UUID?) -> Person? {
      guard let personID else { return nil }
      return store.person(for: personID)
   }

   private func showAddPersonOrPremium() {
      if store.canAddPerson {
         formMode = .add
      } else {
         FAAnalytics.log(.track(.compareSelectionPremiumGateShown, parameters: comparisonSelectionAnalyticsParameters.merging([
            .reason: "person_limit"
         ])))
         isShowingPremium = true
      }
   }

   private var selectionTextColor: Color {
      colorScheme == .dark ? .white.opacity(0.92) : Color(red: 0.24, green: 0.21, blue: 0.29)
   }

   private var comparisonSelectionAnalyticsParameters: FAParameters {
      [
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .didBuyPremium: store.didBuyPremium
      ]
   }
}
