import SwiftUI

/// アプリ内文字サイズを選択する設定画面。
struct TextSizeSettingsView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      List {
         Section {
            ForEach(AppTextSize.allCases) { textSize in
               Button {
                  FAAnalytics.log(.track(.settingsTextSizeSelected, parameters: [
                     .textSize: textSize.rawValue,
                     .previousTextSize: store.textSize.rawValue
                  ]))
                  store.textSize = textSize
               } label: {
                  HStack(spacing: 12) {
                     Text(textSize.title)
                        .font(typography.body)
                        .foregroundStyle(.primary)

                     Spacer()

                     if store.textSize == textSize {
                        Image(systemName: "checkmark")
                           .font(typography.subtext)
                           .foregroundStyle(LikehateTheme.likeAccent)
                     }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .frame(minHeight: layout.rowMinHeight)
                  .contentShape(Rectangle())
               }
               .contentShape(Rectangle())
               .buttonStyle(.plain)
            }
         } footer: {
            Text("TextSizeHelpText")
               .font(typography.subtext)
         }
      }
      .navigationTitle("TextSizeSettingTitle")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
         FAAnalytics.log(.screenView(.textSizeSettings, parameters: [
            .textSize: store.textSize.rawValue
         ]))
      }
   }
}
