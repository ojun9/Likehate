/// アプリ内に同梱しているプリセットプロフィール画像。
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

   /// Asset Catalog上の画像名。
   var assetName: String { rawValue }

   /// UIに表示する1始まりの選択肢番号。
   var optionNumber: Int {
      Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 1
   }

   /// 既存人物が使っていない最初のプリセット画像を返す。
   static func firstAvailable(excluding usedImages: Set<DefaultProfileImage>) -> DefaultProfileImage {
      allCases.first { !usedImages.contains($0) } ?? .defaultProfileImage
   }

   /// ランダムなプリセット画像を返す。
   static func random() -> DefaultProfileImage {
      allCases.randomElement() ?? .defaultProfileImage
   }
}
