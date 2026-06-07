import SwiftUI

/// 好きなもの・嫌いなものを一覧表示し、編集や並び替えを行う画面。
struct ItemListView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var editingItem: LikeDislikeItem?

   let kind: EntryKind
   let personID: UUID?

   init(kind: EntryKind, personID: UUID? = nil) {
      self.kind = kind
      self.personID = personID
   }

   var body: some View {
      Group {
         if let person = selectedPerson {
            itemList(for: person)
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
   }

   private var selectedPerson: Person? {
      if let personID {
         return store.person(for: personID)
      }
      return store.mePerson
   }

   private func itemList(for person: Person) -> some View {
      let items = store.items(for: person.id, kind: kind)
      let itemCount = items.count
      let showsBanner = AdDisplayPolicy(adsRemoved: store.appSettings.adsRemoved, isPremium: store.appSettings.isPremium).showsListAd(hasItems: !items.isEmpty)
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      return ZStack {
         LikehateTheme.background
            .ignoresSafeArea()

         if itemCount == 0 {
            EmptyMemoStateView(
               systemImage: kind == .like ? "heart" : "moon",
               accent: kind.color,
               title: emptyListTitle,
               message: emptyListMessage
            )
            .padding(.horizontal, layout.screenPadding)
            .offset(y: -36)
         } else {
            List {
               Section {
                  ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                     Button {
                        editingItem = item
                     } label: {
                        VStack(spacing: 0) {
                           HStack(spacing: 12) {
                              Text(verbatim: item.title)
                                 .font(typography.prominentListBody)
                                 .foregroundStyle(.primary)
                                 .lineLimit(12)
                                 .multilineTextAlignment(.leading)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                           }
                           .padding(.horizontal, layout.cardPadding)
                           .padding(.vertical, 8)
                           .frame(minHeight: layout.rowMinHeight, alignment: .leading)

                           if index < items.count - 1 {
                              Rectangle()
                                 .fill(LikehateTheme.separator)
                                 .frame(height: 1)
                                 .padding(.horizontal, layout.cardPadding)
                           }
                        }
                     }
                     .buttonStyle(.plain)
                     .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                     .listRowBackground(listSectionRowBackground(rowIndex: index, rowCount: items.count))
                     .listRowSeparator(.hidden)
                     .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                           editingItem = item
                        } label: {
                           Label("EditItemButton", systemImage: "pencil")
                        }
                        .tint(kind.color)
                     }
                  }
                  .onDelete { offsets in
                     store.delete(at: offsets, from: kind, personID: person.id)
                  }
                  .onMove { source, destination in
                     store.move(from: source, to: destination, in: kind, personID: person.id)
                  }
               } header: {
                  HStack(alignment: .firstTextBaseline) {
                     Text(verbatim: kind.title(for: person))
                        .font(typography.cardTitle)
                        .foregroundStyle(.primary)

                     Spacer()

                     Text(verbatim: String.localizedStringWithFormat(String(localized: "ItemsCountFormat"), itemCount))
                        .font(typography.count)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                  }
                  .padding(.horizontal, 2)
                  .padding(.bottom, 8)
                  .textCase(nil)
               } footer: {
                  if showsBanner {
                     ConditionalListAdBanner(placement: .itemList, hasItems: !items.isEmpty, topPadding: 4)
                        .onAppear {
                           FAAnalytics.log(.track(.itemListAdVisible, parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner)))
                        }
                  }
               }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(LikehateTheme.background.ignoresSafeArea())
         }
      }
      .background(LikehateTheme.background.ignoresSafeArea())
      .navigationTitle(kind.listTitle(for: person))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            EditButton()
               .font(typography.subtext)
         }
      }
      .sheet(item: $editingItem) { item in
         NavigationStack {
            EditItemView(kind: kind, person: person, item: item)
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.itemList, parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner)))
      }
   }

   private var emptyListTitle: String {
      switch kind {
      case .like: return String(localized: "EmptyLikesTitle")
      case .hate: return String(localized: "EmptyHatesTitle")
      }
   }

   private var emptyListMessage: String {
      switch kind {
      case .like: return String(localized: "EmptyLikesMessage")
      case .hate: return String(localized: "EmptyHatesMessage")
      }
   }

   private func listSectionRowBackground(rowIndex: Int, rowCount: Int) -> some View {
      let topInset: CGFloat = rowIndex == 0 ? 14 : 0
      let bottomInset: CGFloat = rowIndex == rowCount - 1 ? 14 : 0

      return ZStack(alignment: .leading) {
         LikehateTheme.elevatedSurface

         Rectangle()
            .fill(kind.color.opacity(0.32))
            .frame(width: 3)
            .clipShape(.rect(cornerRadius: 2))
            .padding(.top, topInset)
            .padding(.bottom, bottomInset)
      }
   }

   private func listAnalyticsParameters(person: Person, itemCount: Int, showsBanner: Bool) -> FAParameters {
      [
         .kind: kind.rawValue,
         .itemCount: itemCount,
         .isEmpty: itemCount == 0,
         .showsBanner: showsBanner,
         .didBuyRemoveAd: store.didBuyRemoveAd,
         .personID: person.id.uuidString,
         .isMe: person.isMe,
         .personCount: store.persons.count
      ]
   }
}
