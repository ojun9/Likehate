import Foundation

struct Person: Identifiable, Codable, Hashable {
   var id: UUID
   var name: String
   var profileImageName: String?
   var photoFileName: String?
   var isMe: Bool
   var createdAt: Date
   var updatedAt: Date
   var sortOrder: Int

   var displayName: String {
      let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
      if isMe {
         if trimmedName.isEmpty || trimmedName == "自分" {
            return String(localized: "DefaultMeName")
         }
         return trimmedName
      }

      return trimmedName.isEmpty ? name : trimmedName
   }

   var profileImage: DefaultProfileImage {
      get { DefaultProfileImage(rawValue: profileImageName ?? "") ?? .defaultProfileImage }
      set { profileImageName = newValue.rawValue }
   }
}
