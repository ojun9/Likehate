import Foundation

enum PersonNameRules {
   static let maxLength = 40

   static func limited(_ name: String) -> String {
      String(name.prefix(maxLength))
   }

   static func sanitized(_ rawName: String) -> String {
      let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
      return limited(trimmedName)
   }
}
