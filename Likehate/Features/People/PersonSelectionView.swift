import SwiftUI

/// 人物を選んで入力や閲覧へ進むための一覧画面。
struct PersonSelectionView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var formMode: PersonFormMode?
   @State private var isShowingPremium = false

   let mode: PersonSelectionMode

   var body: some View {
      List {
         Section {
            ForEach(store.persons) { person in
               NavigationLink {
                  destination(for: person)
               } label: {
                  PersonSummaryRow(person: person)
               }
               .contextMenu {
                  Button {
                     formMode = .edit(person)
                  } label: {
                     Label("EditPersonButton", systemImage: "pencil")
                  }
               }
               .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button {
                     formMode = .edit(person)
                  } label: {
                     Label("EditPersonButton", systemImage: "pencil")
                  }
                  .tint(.blue)
               }
            }
         }
      }
      .navigationTitle(mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            Button {
               FAAnalytics.log(.track(.personSelectionAddTapped, parameters: personSelectionAnalyticsParameters))
               showAddPersonOrPremium()
            } label: {
               Image(systemName: "plus")
            }
            .accessibilityLabel(Text("AddPersonButton"))
         }
      }
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
         FAAnalytics.log(.screenView(.personSelection, parameters: personSelectionAnalyticsParameters))
      }
   }

   @ViewBuilder
   private func destination(for person: Person) -> some View {
      switch mode {
      case .register:
         ChooseEntryView(personID: person.id)
      case .browse:
         PersonDetailView(personID: person.id)
      }
   }

   private func showAddPersonOrPremium() {
      if store.canAddPerson {
         formMode = .add
      } else {
         FAAnalytics.log(.track(.personSelectionPremiumGateShown, parameters: personSelectionAnalyticsParameters.merging([
            .reason: "person_limit"
         ])))
         isShowingPremium = true
      }
   }

   private var personSelectionAnalyticsParameters: FAParameters {
      [
         .mode: mode == .register ? "register" : "browse",
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .didBuyPremium: store.didBuyPremium
      ]
   }
}
