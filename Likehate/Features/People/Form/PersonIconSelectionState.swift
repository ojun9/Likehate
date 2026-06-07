/// フォーム上で選択中のプロフィール画像状態。
struct PersonIconSelectionState: Equatable {
   var selectedProfileImage: DefaultProfileImage
   private(set) var removesExistingPhoto: Bool

   private let hasExistingPhoto: Bool

   init(selectedProfileImage: DefaultProfileImage, hasExistingPhoto: Bool) {
      self.selectedProfileImage = selectedProfileImage
      self.hasExistingPhoto = hasExistingPhoto
      self.removesExistingPhoto = false
   }

   mutating func beginPhotoSelection() {}

   mutating func didSelectPhoto() {
      removesExistingPhoto = false
   }

   mutating func selectProfileImage(_ profileImage: DefaultProfileImage) {
      selectedProfileImage = profileImage
      removesExistingPhoto = hasExistingPhoto
   }
}
