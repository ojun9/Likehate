import SwiftUI

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

      FAAnalytics.log(.track(.writeEntrySubmitTapped, parameters: writeAnalyticsParameters(source: source)))
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

   private func writeAnalyticsParameters(source: String) -> FAParameters {
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

      return parameters
   }
}
