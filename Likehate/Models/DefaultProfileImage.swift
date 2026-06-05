enum DefaultProfileImage: String, CaseIterable, Identifiable, Codable, Hashable {
   case defaultProfileImage
   case defaultProfileImage2
   case defaultProfileImage3
   case defaultProfileImage4
   case defaultProfileImage5
   case defaultProfileImage6
   case defaultProfileImage7
   case defaultProfileImage8
   case defaultProfileImage9
   case defaultProfileImage10
   case defaultProfileImage11
   case defaultProfileImage12
   case defaultProfileImage13
   case defaultProfileImage14
   case defaultProfileImage15
   case defaultProfileImage16
   case defaultProfileImage17
   case defaultProfileImage18
   case defaultProfileImage19

   var id: String { rawValue }

   var assetName: String { rawValue }

   var optionNumber: Int {
      Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 1
   }

   static func firstAvailable(excluding usedImages: Set<DefaultProfileImage>) -> DefaultProfileImage {
      allCases.first { !usedImages.contains($0) } ?? .defaultProfileImage
   }

   static func random() -> DefaultProfileImage {
      allCases.randomElement() ?? .defaultProfileImage
   }
}
