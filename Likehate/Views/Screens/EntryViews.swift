import SwiftUI

/// 好きか嫌いのどちらを登録するか選ぶ入口画面。
struct ChooseEntryView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @State private var showsLottie = false

   let personID: UUID?

   init(personID: UUID? = nil) {
      self.personID = personID
   }

   var body: some View {
      Group {
         if let person = selectedPerson {
            GeometryReader { proxy in
               ZStack(alignment: .top) {
                  VStack(spacing: 14) {
                     Text(verbatim: String.localizedStringWithFormat(String(localized: "EntryTargetFormat"), person.displayName))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                     ForEach(EntryKind.allCases) { kind in
                        NavigationLink {
                           WriteItemView(kind: kind, personID: person.id)
                        } label: {
                           VStack(spacing: 8) {
                              Text(verbatim: kind.title(for: person))
                                 .font(.largeTitle.bold())
                                 .fontDesign(.rounded)
                                 .lineLimit(1)
                                 .minimumScaleFactor(0.8)

                              Text(kind.selectionSubtitle)
                                 .font(.callout.weight(.medium))
                                 .fontDesign(.rounded)
                                 .foregroundStyle(.secondary)
                                 .lineLimit(1)
                                 .minimumScaleFactor(0.75)
                           }
                           .frame(maxWidth: .infinity, minHeight: 132)
                           .padding(.horizontal, 20)
                           .padding(.vertical, 16)
                           .background(LikehateTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                           .overlay(
                              RoundedRectangle(cornerRadius: 22, style: .continuous)
                                 .stroke(kind.color.opacity(colorScheme == .dark ? 0.2 : 0.14), lineWidth: 1)
                           )
                           .overlay(alignment: kind == .like ? .leading : .trailing) {
                              if store.animationEnabled && showsLottie {
                                 LottieLoopView(name: kind == .like ? "Egg" : "MaruKuru")
                                    .opacity(0.42)
                                    .frame(width: 96, height: 96)
                                    .clipped()
                                    .padding(.horizontal, 12)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                              }
                           }
                           .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 12, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                           FAAnalytics.log(.track(.chooseEntryKindTapped, parameters: [
                              .kind: kind.rawValue,
                              .personID: person.id.uuidString,
                              .isMe: person.isMe
                           ]))
                        })
                     }
                  }
                  .padding(.horizontal, 20)
                  .padding(.top, max(proxy.safeAreaInsets.top + 18, 32))
               }
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle("ChooseEntryTitle")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
         FAAnalytics.log(.screenView(.chooseEntry, parameters: chooseAnalyticsParameters))
         HapticsClient.medium()
      }
      .task {
         try? await Task.sleep(for: .milliseconds(350))
         showsLottie = true
      }
      .onDisappear {
         showsLottie = false
      }
   }

   private var selectedPerson: Person? {
      if let personID {
         return store.person(for: personID)
      }
      return store.mePerson
   }

   private var chooseAnalyticsParameters: FAParameters {
      var parameters: FAParameters = [
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .animationEnabled: store.animationEnabled
      ]

      if let selectedPerson {
         parameters[.personID] = selectedPerson.id.uuidString
         parameters[.isMe] = selectedPerson.isMe
      }

      return parameters
   }
}

/// 好き嫌いのテキストを入力して保存する画面。
struct WriteItemView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @Environment(\.colorScheme) private var colorScheme
   @State private var text = ""
   @State private var showEmptyAlert = false
   @State private var lottieName: String
   @FocusState private var isTextFieldFocused: Bool

   let kind: EntryKind
   let personID: UUID?

   init(kind: EntryKind, personID: UUID? = nil) {
      self.kind = kind
      self.personID = personID
      _lottieName = State(initialValue: EntryLottieSelection.randomName(for: kind))
   }

   var body: some View {
      Group {
         if let person = selectedPerson {
            GeometryReader { proxy in
               ZStack(alignment: .top) {
                  LikehateTheme.background
                     .ignoresSafeArea()

                  if store.animationEnabled {
                     WriteLottieLayer(lottieName: lottieName, kind: kind, keepsFullHeight: isTextFieldFocused)
                  }

                  ScrollView {
                     VStack(spacing: 0) {
                        Text(verbatim: String.localizedStringWithFormat(String(localized: "WriteTargetFormat"), person.displayName))
                           .font(.subheadline.weight(.medium))
                           .foregroundStyle(.secondary)
                           .padding(.bottom, 14)

                        TextField(kind.inputPlaceholder(for: person), text: $text)
                           .font(.body.weight(.semibold))
                           .fontDesign(.rounded)
                           .textInputAutocapitalization(.sentences)
                           .submitLabel(.done)
                           .onSubmit {
                              save(source: "keyboard", person: person)
                           }
                           .focused($isTextFieldFocused)
                           .padding(.horizontal, 16)
                           .frame(minHeight: 52)
                           .foregroundStyle(.primary)
                           .background(fieldBackgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                           .overlay(
                              RoundedRectangle(cornerRadius: 18, style: .continuous)
                                 .stroke(fieldBorderColor, lineWidth: isTextFieldFocused ? 1.5 : 1)
                           )
                           .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                           .shadow(color: isTextFieldFocused ? kind.color.opacity(colorScheme == .dark ? 0.18 : 0.1) : LikehateTheme.cardShadow(for: colorScheme), radius: isTextFieldFocused ? 10 : 6, x: 0, y: 3)
                           .padding(.horizontal, 36)

                        Button {
                           save(source: "button", person: person)
                        } label: {
                           Text(verbatim: kind.inputButtonTitle(for: person))
                              .font(.body.weight(.bold))
                              .fontDesign(.rounded)
                              .lineLimit(1)
                              .minimumScaleFactor(0.75)
                              .frame(maxWidth: .infinity)
                              .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(kind.color)
                        .frame(width: registerButtonWidth(for: proxy.size.width))
                        .clipShape(Capsule())
                        .controlSize(.regular)
                        .padding(.top, 18)
                     }
                     .padding(.top, 32)
                     .padding(.bottom, 180)
                     .frame(maxWidth: .infinity)
                  }
                  .scrollIndicators(.hidden)
               }
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle(selectedPerson.map { kind.title(for: $0) } ?? kind.title)
      .alert("EmptyInputAlert", isPresented: $showEmptyAlert) {
         Button("OK", role: .cancel) {}
      }
      .alert(item: $store.reviewPrompt) { prompt in
         Alert(
            title: Text(prompt.title),
            message: Text(prompt.message),
            primaryButton: .default(Text("ThankYou")) {
               FAAnalytics.log(.track(.reviewPromptConfirmed, parameters: [
                  .screen: FAScreen.writeEntry.rawValue
               ]))
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               FAAnalytics.log(.track(.reviewPromptCancelled, parameters: [
                  .screen: FAScreen.writeEntry.rawValue
               ]))
            }
         )
      }
      .onAppear {
         lottieName = EntryLottieSelection.randomName(for: kind, excluding: lottieName)
         FAAnalytics.log(.screenView(.writeEntry, parameters: writeAnalyticsParameters(source: "appear")))
         Task {
            try? await Task.sleep(for: .milliseconds(250))
            isTextFieldFocused = true
         }
      }
      .onDisappear {
         isTextFieldFocused = false
         FAAnalytics.log(.track(.writeEntryDisappeared, parameters: writeAnalyticsParameters(source: "disappear")))
      }
      .onChange(of: isTextFieldFocused) { _, isFocused in
         FAAnalytics.log(.track(.writeTextFieldFocusChanged, parameters: writeAnalyticsParameters(source: isFocused ? "focused" : "unfocused")))
      }
   }

   private var selectedPerson: Person? {
      if let personID {
         return store.person(for: personID)
      }
      return store.mePerson
   }

   private func save(source: String, person: Person) {
      guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
         FAAnalytics.log(.track(.writeEntryEmptySubmitted, parameters: writeAnalyticsParameters(source: source)))
         HapticsClient.error()
         showEmptyAlert = true
         return
      }

      FAAnalytics.log(.track(.writeEntrySubmitTapped, parameters: writeAnalyticsParameters(source: source, includesEntryText: true)))
      store.add(text, to: kind, personID: person.id)
      dismiss()
   }

   private func registerButtonWidth(for containerWidth: CGFloat) -> CGFloat {
      let availableWidth = min(containerWidth * 0.58, 228)
      guard availableWidth.isFinite else { return 0 }
      return max(156, availableWidth)
   }

   private var fieldBackgroundColor: Color {
      if isTextFieldFocused {
         return LikehateTheme.tintFill(kind.color, scheme: colorScheme)
      }
      return LikehateTheme.inputSurface
   }

   private var fieldBorderColor: Color {
      isTextFieldFocused ? kind.color.opacity(0.46) : LikehateTheme.border
   }

   private func writeAnalyticsParameters(source: String, includesEntryText: Bool = false) -> FAParameters {
      var parameters: FAParameters = [
         .kind: kind.rawValue,
         .source: source,
         .textLength: text.trimmingCharacters(in: .whitespacesAndNewlines).count,
         .lottieName: lottieName,
         .isFocused: isTextFieldFocused,
         .likeCount: store.likes.count,
         .hateCount: store.hates.count,
         .entryCount: store.totalItemCount,
         .animationEnabled: store.animationEnabled
      ]

      if let selectedPerson {
         parameters[.personID] = selectedPerson.id.uuidString
         parameters[.isMe] = selectedPerson.isMe
      }

      if includesEntryText, let entryText = FAEntryTextParameter.value(from: text) {
         parameters[.entryText] = entryText
      }

      return parameters
   }
}

/// 入力画面上部にLottieを安全に重ねる背景レイヤー。
struct WriteLottieLayer: View {
   let lottieName: String
   let kind: EntryKind
   let keepsFullHeight: Bool
   @State private var largestSize: CGSize = .zero

   var body: some View {
      GeometryReader { proxy in
         let stableHeight = keepsFullHeight ? max(largestSize.height, proxy.size.height) : proxy.size.height

         ZStack(alignment: .top) {
            LottieLoopView(name: lottieName)
               .frame(width: proxy.size.width * 0.96, height: max(stableHeight - 15, 120))
               .frame(maxWidth: .infinity, alignment: .top)
               .padding(.horizontal, proxy.size.width * 0.02)
         }
         .frame(width: proxy.size.width, height: stableHeight, alignment: .top)
         .onAppear {
            largestSize = proxy.size
         }
         .onChange(of: proxy.size) { _, newSize in
            if !keepsFullHeight || newSize.height > largestSize.height {
               largestSize = newSize
            }
         }
      }
      .opacity(kind == .like ? 0.72 : 0.32)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .ignoresSafeArea(.container, edges: .top)
      .ignoresSafeArea(.keyboard, edges: .bottom)
   }
}

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
               }

               if showsBanner {
                  ConditionalListAdBanner(placement: .itemList, hasItems: !items.isEmpty)
                     .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                     .listRowSeparator(.hidden)
                     .listRowBackground(Color.clear)
                     .onAppear {
                        FAAnalytics.log(.track(.itemListAdVisible, parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner)))
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

private struct EditItemView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @FocusState private var isTextFieldFocused: Bool

   let kind: EntryKind
   let person: Person
   let item: LikeDislikeItem
   @State private var text: String

   init(kind: EntryKind, person: Person, item: LikeDislikeItem) {
      self.kind = kind
      self.person = person
      self.item = item
      _text = State(initialValue: item.title)
   }

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      ScrollView {
         VStack(alignment: .leading, spacing: layout.cardSpacing) {
            TextField(kind.inputPlaceholder(for: person), text: $text, axis: .vertical)
               .font(typography.body)
               .lineLimit(2...8)
               .focused($isTextFieldFocused)
               .submitLabel(.done)
               .padding(layout.cardPadding)
               .background(LikehateTheme.inputSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
               .overlay(
                  RoundedRectangle(cornerRadius: 18, style: .continuous)
                     .stroke(kind.color.opacity(isTextFieldFocused ? 0.42 : 0.16), lineWidth: isTextFieldFocused ? 1.5 : 1)
               )

            Button {
               guard store.updateItem(item.id, title: text) else { return }
               dismiss()
            } label: {
               Text("SaveItemButton")
                  .font(typography.button)
                  .frame(maxWidth: .infinity)
                  .frame(minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(kind.color)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
         }
         .padding(layout.screenPadding)
      }
      .background(LikehateTheme.background.ignoresSafeArea())
      .navigationTitle("EditItemTitle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .cancellationAction) {
            Button("cancel") {
               dismiss()
            }
            .font(typography.subtext)
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.editItem, parameters: [
            .kind: kind.rawValue,
            .personID: person.id.uuidString,
            .isMe: person.isMe,
            .textLength: text.trimmingCharacters(in: .whitespacesAndNewlines).count
         ]))
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isTextFieldFocused = true
         }
      }
   }
}
