import FirebaseAnalytics
import SwiftUI

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
                           Analytics.logEvent("choose_entry_kind_tapped", parameters: [
                              "kind": kind.rawValue,
                              "person_id": person.id.uuidString,
                              "is_me": person.isMe
                           ])
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
         Analytics.logEvent("screen_view_choose_entry", parameters: chooseAnalyticsParameters)
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

   private var chooseAnalyticsParameters: [String: Any] {
      var parameters: [String: Any] = [
         "person_count": store.persons.count,
         "entry_count": store.totalItemCount,
         "animation_enabled": store.animationEnabled
      ]

      if let selectedPerson {
         parameters["person_id"] = selectedPerson.id.uuidString
         parameters["is_me"] = selectedPerson.isMe
      }

      return parameters
   }
}

struct WriteItemView: View {
   private static let likeLottieNames = ["MoreHarts", "heart1", "heart2"]
   private static let hateLottieNames = ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"]

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
      switch kind {
      case .like:
         _lottieName = State(initialValue: Self.likeLottieNames.randomElement() ?? "MoreHarts")
      case .hate:
         _lottieName = State(initialValue: Self.hateLottieNames.randomElement() ?? "fish")
      }
   }

   var body: some View {
      Group {
         if let person = selectedPerson {
            GeometryReader { proxy in
               ZStack(alignment: .top) {
                  LikehateTheme.background
                     .ignoresSafeArea()

                  if store.animationEnabled {
                     WriteLottieLayer(lottieName: lottieName, kind: kind, topOffset: kind == .like ? 238 : 252, keepsFullHeight: isTextFieldFocused)
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
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               Analytics.logEvent("UserTap_OhThanks...For100", parameters: nil)
            }
         )
      }
      .onAppear {
         Analytics.logEvent("screen_view_write_entry", parameters: writeAnalyticsParameters(source: "appear"))
         Task {
            try? await Task.sleep(for: .milliseconds(250))
            isTextFieldFocused = true
         }
      }
      .onDisappear {
         isTextFieldFocused = false
         Analytics.logEvent("write_entry_disappeared", parameters: writeAnalyticsParameters(source: "disappear"))
      }
      .onChange(of: isTextFieldFocused) { _, isFocused in
         Analytics.logEvent("write_text_field_focus_changed", parameters: writeAnalyticsParameters(source: isFocused ? "focused" : "unfocused"))
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
         Analytics.logEvent("write_entry_empty_submitted", parameters: writeAnalyticsParameters(source: source))
         HapticsClient.error()
         showEmptyAlert = true
         return
      }

      Analytics.logEvent("write_entry_submit_tapped", parameters: writeAnalyticsParameters(source: source))
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

   private func writeAnalyticsParameters(source: String) -> [String: Any] {
      var parameters: [String: Any] = [
         "kind": kind.rawValue,
         "source": source,
         "text_length": text.trimmingCharacters(in: .whitespacesAndNewlines).count,
         "lottie_name": lottieName,
         "is_focused": isTextFieldFocused,
         "like_count": store.likes.count,
         "hate_count": store.hates.count,
         "entry_count": store.totalItemCount,
         "animation_enabled": store.animationEnabled
      ]

      if let selectedPerson {
         parameters["person_id"] = selectedPerson.id.uuidString
         parameters["is_me"] = selectedPerson.isMe
      }

      return parameters
   }
}

struct WriteLottieLayer: View {
   let lottieName: String
   let kind: EntryKind
   let topOffset: CGFloat
   let keepsFullHeight: Bool
   @State private var largestSize: CGSize = .zero

   var body: some View {
      GeometryReader { proxy in
         let stableHeight = keepsFullHeight ? max(largestSize.height, proxy.size.height) : proxy.size.height

         VStack {
            Spacer(minLength: topOffset)

            LottieLoopView(name: lottieName)
               .frame(width: proxy.size.width * 0.96, height: max(stableHeight - topOffset - 15, 120))
               .frame(maxWidth: .infinity)
               .padding(.horizontal, proxy.size.width * 0.02)
               .padding(.bottom, 15)
         }
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
      .ignoresSafeArea(.keyboard, edges: .bottom)
   }
}

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
      let showsBanner = !store.didBuyRemoveAd && !items.isEmpty
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
                  ForEach(items) { item in
                     Button {
                        editingItem = item
                     } label: {
                        HStack(spacing: 12) {
                           Text(verbatim: item.title)
                              .font(typography.body)
                              .foregroundStyle(.primary)
                              .lineLimit(12)
                              .multilineTextAlignment(.leading)
                              .frame(maxWidth: .infinity, alignment: .leading)

                           Image(systemName: "pencil")
                              .font(typography.subtext)
                              .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)
                        .frame(minHeight: layout.rowMinHeight, alignment: .leading)
                     }
                     .buttonStyle(.plain)
                     .listRowInsets(EdgeInsets(top: 0, leading: layout.cardPadding, bottom: 0, trailing: layout.cardPadding))
                     .listRowBackground(LikehateTheme.elevatedSurface)
                     .listRowSeparatorTint(LikehateTheme.separator)
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
                  LikehateAdaptiveAdBanner(adUnitID: AdMobUnitID.itemListBanner)
                     .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                     .listRowSeparator(.hidden)
                     .listRowBackground(Color.clear)
                     .onAppear {
                        Analytics.logEvent("list_banner_visible", parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner))
                     }
               }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(LikehateTheme.background)
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
         Analytics.logEvent(kind == .like ? "showLikeTableView" : "showHateTableView", parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner))
         Analytics.logEvent("screen_view_item_list", parameters: listAnalyticsParameters(person: person, itemCount: itemCount, showsBanner: showsBanner))
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

   private func listAnalyticsParameters(person: Person, itemCount: Int, showsBanner: Bool) -> [String: Any] {
      [
         "kind": kind.rawValue,
         "item_count": itemCount,
         "is_empty": itemCount == 0,
         "shows_banner": showsBanner,
         "did_buy_remove_ad": store.didBuyRemoveAd,
         "person_id": person.id.uuidString,
         "is_me": person.isMe,
         "person_count": store.persons.count
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
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isTextFieldFocused = true
         }
      }
   }
}
