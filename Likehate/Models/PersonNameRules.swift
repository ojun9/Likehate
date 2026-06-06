import Foundation

/// 人物名の入力・保存に共通して使う整形ルール。
enum PersonNameRules {
   /// 人物名として保存できる最大文字数。
   static let maxLength = 40

   /// 最大文字数で切り詰めた名前を返す。
   static func limited(_ name: String) -> String {
      String(name.prefix(maxLength))
   }

   /// 前後空白を取り除き、最大文字数を適用した名前を返す。
   static func sanitized(_ rawName: String) -> String {
      let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
      return limited(trimmedName)
   }
}
