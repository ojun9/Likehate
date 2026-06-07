import SwiftUI
import UIKit

/// 写真またはプリセット画像を丸いアバターとして表示する共通View。
struct PersonAvatar: View {
   @EnvironmentObject private var store: LikeHateStore

   let person: Person
   var size: CGFloat = 38
   var showsShadow = true

   var body: some View {
      PersonAvatarContent(
         image: store.photoImage(for: person),
         profileImage: person.profileImage,
         size: size,
         showsShadow: showsShadow
      )
   }
}

struct PersonAvatarContent: View {
   let image: UIImage?
   let profileImage: DefaultProfileImage
   let size: CGFloat
   var showsShadow = true

   var body: some View {
      avatarImage
         .resizable()
         .scaledToFill()
         .frame(width: size, height: size)
         .clipShape(Circle())
         .overlay {
            Circle()
               .stroke(.white.opacity(0.16), lineWidth: 1)
         }
         .shadow(color: showsShadow ? Color.black.opacity(0.08) : .clear, radius: showsShadow ? 5 : 0, x: 0, y: showsShadow ? 2 : 0)
   }

   private var avatarImage: Image {
      if let image {
         return Image(uiImage: image)
      }
      return Image(profileImage.assetName)
   }
}
