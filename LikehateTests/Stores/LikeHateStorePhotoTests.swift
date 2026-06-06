import Foundation
import Testing
import UIKit
@testable import Likehate

@MainActor
struct LikeHateStorePhotoTests {
   @Test("写真データは正方形画像サムネイルへ変換される")
   func photoDataIsConvertedIntoSquareThumbnail() throws {
      let sourceData = try TestImageFactory.jpegData(size: CGSize(width: 80, height: 40), color: .systemPink)
      let thumbnailData = try #require(LikeHateStore.thumbnailPhotoData(from: sourceData))
      let thumbnail = try #require(UIImage(data: thumbnailData))

      #expect(Int(thumbnail.size.width) == 512)
      #expect(Int(thumbnail.size.height) == 512)
   }

   @Test("不正な写真データは拒否される")
   func invalidPhotoDataIsRejected() {
      #expect(LikeHateStore.thumbnailPhotoData(from: Data("not image".utf8)) == nil)
   }

   @Test("人物写真は保存読込削除でき人物削除時にも消える")
   func personPhotoLifecycle() throws {
      let context = try StoreTestContext()
      defer {
         context.store.deleteAll()
         context.cleanup()
      }

      let store = context.store
      let photoData = try TestImageFactory.jpegData(size: CGSize(width: 72, height: 120), color: .systemBlue)
      let person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3, photoData: photoData))
      let storedPerson = try #require(store.person(for: person.id))
      let photoFileName = try #require(storedPerson.photoFileName)
      let photoURL = try #require(store.photoURL(for: storedPerson))

      #expect(photoFileName == "person_\(person.id.uuidString).jpg")
      #expect(FileManager.default.fileExists(atPath: photoURL.path))
      #expect(store.photoImage(for: storedPerson) != nil)

      store.updatePerson(person.id, name: "太郎", removesPhoto: true)
      let photoRemovedPerson = try #require(store.person(for: person.id))
      #expect(photoRemovedPerson.photoFileName == nil)
      #expect(FileManager.default.fileExists(atPath: photoURL.path) == false)

      let replacementData = try TestImageFactory.jpegData(size: CGSize(width: 60, height: 60), color: .systemGreen)
      store.updatePerson(person.id, name: "太郎", photoData: replacementData)
      let replacedPerson = try #require(store.person(for: person.id))
      let replacedPhotoURL = try #require(store.photoURL(for: replacedPerson))
      #expect(FileManager.default.fileExists(atPath: replacedPhotoURL.path))

      store.deletePerson(person.id)
      #expect(FileManager.default.fileExists(atPath: replacedPhotoURL.path) == false)
   }

   @Test("プリセット画像更新は既存写真を削除する")
   func presetProfileImageUpdateRemovesExistingPhoto() throws {
      let context = try StoreTestContext()
      defer {
         context.store.deleteAll()
         context.cleanup()
      }

      let store = context.store
      let photoData = try TestImageFactory.jpegData(size: CGSize(width: 96, height: 96), color: .systemPurple)
      let person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3, photoData: photoData))
      let photoPerson = try #require(store.person(for: person.id))
      let photoURL = try #require(store.photoURL(for: photoPerson))

      store.updatePerson(person.id, name: "太郎", profileImage: .defaultProfileImage11, removesPhoto: true)
      let updatedPerson = try #require(store.person(for: person.id))

      #expect(updatedPerson.profileImageName == DefaultProfileImage.defaultProfileImage11.rawValue)
      #expect(updatedPerson.photoFileName == nil)
      #expect(FileManager.default.fileExists(atPath: photoURL.path) == false)
   }

   @Test("存在しない写真ファイルは無視される")
   func missingPhotoFileIsIgnored() throws {
      let context = try StoreTestContext()
      defer { context.cleanup() }

      let store = context.store
      var person = try #require(store.addPerson(named: "太郎", profileImage: .defaultProfileImage3))
      person.photoFileName = "person_missing.jpg"

      #expect(store.photoURL(for: person) == nil)
      #expect(store.photoImage(for: person) == nil)
   }
}
