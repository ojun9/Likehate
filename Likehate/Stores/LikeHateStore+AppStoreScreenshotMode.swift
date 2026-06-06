#if DEBUG
import Foundation

/// App Store用スクリーンショット撮影のために、実データを一時的にサンプルデータへ差し替えるデバッグ拡張。
@MainActor
extension LikeHateStore {
   private enum AppStoreScreenshotModeConstants {
      static let modeEnabledKey = "DebugAppStoreScreenshotModeEnabled"
      static let backupPersonsKey = "DebugAppStoreScreenshotBackupPersonsV1"
      static let backupItemsKey = "DebugAppStoreScreenshotBackupItemsV1"
      static let sampleDelimiter: Character = "|"
   }

   /// スクリーンショット用サンプルデータモードが有効かどうか。
   var isAppStoreScreenshotModeEnabled: Bool {
      defaults.bool(forKey: AppStoreScreenshotModeConstants.modeEnabledKey)
   }

   /// スクリーンショット用サンプルデータモードのON/OFFを切り替える。
   func setAppStoreScreenshotModeEnabled(_ isEnabled: Bool) {
      guard isEnabled != isAppStoreScreenshotModeEnabled else { return }

      if isEnabled {
         enableAppStoreScreenshotMode()
      } else {
         restoreDataFromAppStoreScreenshotMode()
      }
   }

   /// 現在のデータを退避して、スクリーンショット用の人物と好き嫌いへ差し替える。
   private func enableAppStoreScreenshotMode() {
      backupCurrentDataForAppStoreScreenshotMode()

      let sampleData = Self.makeAppStoreScreenshotData(now: Date(), locale: Self.appStoreScreenshotLocale)
      replacePeopleAndEntries(persons: sampleData.persons, entries: sampleData.entries)
      defaults.set(true, forKey: AppStoreScreenshotModeConstants.modeEnabledKey)
      persistPeopleAndEntries()
   }

   /// 退避した実データを復元し、退避データがない場合は初期状態へ戻す。
   private func restoreDataFromAppStoreScreenshotMode() {
      let now = Date()
      if
         let backedUpPersons: [Person] = Self.decodeAppStoreScreenshotBackup([Person].self, forKey: AppStoreScreenshotModeConstants.backupPersonsKey, defaults: defaults),
         let backedUpEntries: [LikeDislikeItem] = Self.decodeAppStoreScreenshotBackup([LikeDislikeItem].self, forKey: AppStoreScreenshotModeConstants.backupItemsKey, defaults: defaults)
      {
         let restoredPersons = Self.normalizedPersons(backedUpPersons, now: now)
         let validPersonIDs = Set(restoredPersons.map(\.id))
         replacePeopleAndEntries(
            persons: restoredPersons,
            entries: backedUpEntries.filter { validPersonIDs.contains($0.personId) }
         )
         normalizeSortOrders()
      } else {
         replacePeopleAndEntries(
            persons: [Self.makeMePerson(now: now, sortOrder: 0)],
            entries: []
         )
      }

      defaults.removeObject(forKey: AppStoreScreenshotModeConstants.backupPersonsKey)
      defaults.removeObject(forKey: AppStoreScreenshotModeConstants.backupItemsKey)
      defaults.set(false, forKey: AppStoreScreenshotModeConstants.modeEnabledKey)
      persistPeopleAndEntries()
   }

   private func backupCurrentDataForAppStoreScreenshotMode() {
      persistAppStoreScreenshotBackup(persons, forKey: AppStoreScreenshotModeConstants.backupPersonsKey)
      persistAppStoreScreenshotBackup(entries, forKey: AppStoreScreenshotModeConstants.backupItemsKey)
   }

   private func persistAppStoreScreenshotBackup<T: Encodable>(_ value: T, forKey key: String) {
      guard let data = try? JSONEncoder().encode(value) else { return }
      defaults.set(data, forKey: key)
   }

   private static func decodeAppStoreScreenshotBackup<T: Decodable>(_ type: T.Type, forKey key: String, defaults: UserDefaults) -> T? {
      guard let data = defaults.data(forKey: key) else { return nil }
      return try? JSONDecoder().decode(type, from: data)
   }

   private static let appStoreScreenshotMeID = UUID(uuidString: "00000000-0000-0000-0000-000000000101") ?? UUID()
   private static let appStoreScreenshotSecondPersonID = UUID(uuidString: "00000000-0000-0000-0000-000000000102") ?? UUID()
   private static let appStoreScreenshotThirdPersonID = UUID(uuidString: "00000000-0000-0000-0000-000000000103") ?? UUID()

   private static var appStoreScreenshotLocale: Locale {
      let preferredIdentifier = Bundle.main.preferredLocalizations.first ?? Locale.current.identifier
      return Locale(identifier: preferredIdentifier)
   }

   private static func localizedAppStoreScreenshotString(_ key: String, locale: Locale) -> String {
      let identifier = locale.identifier
      let languageCode = identifier.split(separator: "_").first.map(String.init)
      let preferences = [identifier, languageCode].compactMap(\.self)
      let localization = Bundle.preferredLocalizations(
         from: Bundle.main.localizations,
         forPreferences: preferences
      ).first
      let localizedBundle = localization
         .flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }
         .flatMap(Bundle.init(path:)) ?? .main
      let value = localizedBundle.localizedString(forKey: key, value: key, table: "Localizable")

      return value == key ? Bundle.main.localizedString(forKey: key, value: key, table: "Localizable") : value
   }

   private static func localizedAppStoreScreenshotTitles(_ key: String, locale: Locale) -> [String] {
      localizedAppStoreScreenshotString(key, locale: locale)
         .split(separator: AppStoreScreenshotModeConstants.sampleDelimiter)
         .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
         .filter { $0.isEmpty == false }
   }

   /// スクリーンショット用に見栄えと比較結果を調整した固定サンプルデータを作る。
   static func makeAppStoreScreenshotData(now: Date, locale: Locale) -> (persons: [Person], entries: [LikeDislikeItem]) {
      let persons = [
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotMeID,
            name: localizedAppStoreScreenshotString("DefaultMeName", locale: locale),
            profileImage: .defaultProfileImage,
            isMe: true,
            now: now,
            sortOrder: 0
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotSecondPersonID,
            name: localizedAppStoreScreenshotString("AppStoreScreenshotSampleSecondPersonName", locale: locale),
            profileImage: .defaultProfileImage6,
            isMe: false,
            now: now,
            sortOrder: 1
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotThirdPersonID,
            name: localizedAppStoreScreenshotString("AppStoreScreenshotSampleThirdPersonName", locale: locale),
            profileImage: .defaultProfileImage16,
            isMe: false,
            now: now,
            sortOrder: 2
         )
      ]

      let entries =
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotMeID,
            kind: .like,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleMeLikes", locale: locale),
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotMeID,
            kind: .hate,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleMeHates", locale: locale),
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .like,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleSecondPersonLikes", locale: locale),
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .hate,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleSecondPersonHates", locale: locale),
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .like,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleThirdPersonLikes", locale: locale),
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .hate,
            titles: localizedAppStoreScreenshotTitles("AppStoreScreenshotSampleThirdPersonHates", locale: locale),
            now: now
         )

      return (persons, entries)
   }

   /// サンプルデータ用の人物を固定IDと並び順で作る。
   private static func makeAppStoreScreenshotPerson(
      id: UUID,
      name: String,
      profileImage: DefaultProfileImage,
      isMe: Bool,
      now: Date,
      sortOrder: Int
   ) -> Person {
      Person(
         id: id,
         name: name,
         profileImageName: profileImage.rawValue,
         photoFileName: nil,
         isMe: isMe,
         createdAt: now.addingTimeInterval(TimeInterval(sortOrder)),
         updatedAt: now,
         sortOrder: sortOrder
      )
   }

   /// サンプルデータ用の記録を表示順つきでまとめて作る。
   private static func makeAppStoreScreenshotEntries(
      personID: UUID,
      kind: EntryKind,
      titles: [String],
      now: Date
   ) -> [LikeDislikeItem] {
      titles.enumerated().map { offset, title in
         LikeDislikeItem(
            id: UUID(),
            personId: personID,
            type: kind,
            title: title,
            note: nil,
            createdAt: now.addingTimeInterval(TimeInterval(offset)),
            updatedAt: now,
            sortOrder: offset
         )
      }
   }
}
#endif
