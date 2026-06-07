import SwiftUI

struct EditItemView: View {
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
