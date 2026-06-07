import SwiftUI

/// 設定画面でアイコン、タイトル、補足値を横並びで表示する行View。
struct SettingsActionRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let iconName: String
   let title: LocalizedStringKey
   var subtitle: LocalizedStringKey?
   var value: LocalizedStringKey?
   var iconColor: Color = .primary
   var titleWeight: Font.Weight = .regular

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         Image(systemName: iconName)
            .font(typography.body)
            .foregroundStyle(iconColor)
            .frame(width: 24, alignment: .center)

         VStack(alignment: .leading, spacing: 3) {
            Text(title)
               .font(typography.bodyRegular)
               .fontWeight(titleWeight)
               .foregroundStyle(.primary)

            if let subtitle {
               Text(subtitle)
                  .font(typography.subtext)
                  .foregroundStyle(.secondary)
            }
         }

         Spacer(minLength: 0)

         if let value {
            Text(value)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
         }
      }
      .frame(minHeight: layout.rowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}

/// 設定画面でアプリバージョンを表示する行View。
struct SettingsVersionRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let versionText: String

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         Image(systemName: "info.circle")
            .font(typography.body)
            .foregroundStyle(.primary)
            .frame(width: 24, alignment: .center)

         Text("Version")
            .font(typography.bodyRegular)
            .foregroundStyle(.primary)

         Spacer(minLength: 8)

         Text(verbatim: versionText)
            .font(typography.subtext.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
      }
      .frame(minHeight: layout.rowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
   }
}

/// 復元処理など進行中の設定アクションを表示する行View。
struct SettingsProgressRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: LocalizedStringKey

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 12) {
         ProgressView()
            .frame(width: 24, alignment: .center)

         Text(title)
            .font(typography.bodyRegular)
            .foregroundStyle(.primary)

         Spacer(minLength: 0)
      }
      .frame(minHeight: layout.rowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
   }
}
