import Foundation
import Testing
@testable import Likehate

func makePerson(
   name: String,
   profileImageName: String? = DefaultProfileImage.defaultProfileImage.rawValue,
   isMe: Bool
) -> Person {
   Person(
      id: UUID(),
      name: name,
      profileImageName: profileImageName,
      photoFileName: nil,
      isMe: isMe,
      createdAt: Date(),
      updatedAt: Date(),
      sortOrder: 0
   )
}

func makeItem(
   title: String,
   personID: UUID,
   kind: EntryKind = .like,
   sortOrder: Int
) -> LikeDislikeItem {
   LikeDislikeItem(
      id: UUID(),
      personId: personID,
      type: kind,
      title: title,
      note: nil,
      createdAt: Date(),
      updatedAt: Date(),
      sortOrder: sortOrder
   )
}
