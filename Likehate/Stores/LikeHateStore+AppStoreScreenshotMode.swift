#if DEBUG
import Foundation

/// App Store用スクリーンショット撮影のために、実データを一時的にサンプルデータへ差し替えるデバッグ拡張。
@MainActor
extension LikeHateStore {
   private enum AppStoreScreenshotModeConstants {
      static let modeEnabledKey = "DebugAppStoreScreenshotModeEnabled"
      static let backupPersonsKey = "DebugAppStoreScreenshotBackupPersonsV1"
      static let backupItemsKey = "DebugAppStoreScreenshotBackupItemsV1"
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

      let sampleData = Self.makeAppStoreScreenshotData(now: Date())
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

   /// スクリーンショット用に見栄えと比較結果を調整した固定サンプルデータを作る。
   private static func makeAppStoreScreenshotData(now: Date) -> (persons: [Person], entries: [LikeDislikeItem]) {
      let persons = [
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotMeID,
            name: String(localized: "DefaultMeName"),
            profileImage: .defaultProfileImage,
            isMe: true,
            now: now,
            sortOrder: 0
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotSecondPersonID,
            name: "あかり",
            profileImage: .defaultProfileImage6,
            isMe: false,
            now: now,
            sortOrder: 1
         ),
         makeAppStoreScreenshotPerson(
            id: appStoreScreenshotThirdPersonID,
            name: "はると",
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
            titles: [
               "おすし",
               "映画館",
               "夜の散歩",
               "カフェラテ",
               "チーズケーキ",
               "読書",
               "温泉",
               "ボードゲーム",
               "猫カフェ",
               "美術館",
               "ハンバーグ",
               "朝のラジオ",
               "花火",
               "パン屋めぐり",
               "雨上がりの空",
               "季節の果物",
               "静かな朝",
               "手帳を書く",
               "焼きたてのパン",
               "植物の世話",
               "夕方の音楽",
               "ほうじ茶",
               "小さな旅"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotMeID,
            kind: .hate,
            titles: [
               "早起き",
               "人混み",
               "辛すぎる料理",
               "満員電車",
               "虫",
               "大きな音",
               "長い行列",
               "冷たい雨",
               "急な予定変更",
               "煙草のにおい",
               "ホラー映画",
               "徹夜",
               "狭い席",
               "強い香水",
               "締め切り前の焦り",
               "冷めたごはん"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .like,
            titles: [
               "チーズケーキ",
               "映画館",
               "美術館",
               "カフェラテ",
               "おすし",
               "パン屋めぐり",
               "花火",
               "水族館",
               "手紙を書く",
               "夜景",
               "読書",
               "抹茶ラテ",
               "ピクニック",
               "古着屋めぐり",
               "温泉",
               "いちごタルト",
               "公園ランチ",
               "手作り雑貨",
               "星を見る",
               "アロマ",
               "写真を撮る",
               "小さな花束",
               "手作りクッキー",
               "雑貨屋さん",
               "夕焼け",
               "日記を書く",
               "ホットケーキ",
               "海の見えるカフェ",
               "やわらかい毛布"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotSecondPersonID,
            kind: .hate,
            titles: [
               "虫",
               "満員電車",
               "辛すぎる料理",
               "早起き",
               "大きな音",
               "煙草のにおい",
               "長い行列",
               "寒すぎる部屋",
               "ホラー映画",
               "炭酸飲料",
               "徹夜",
               "急な予定変更",
               "生たまねぎ",
               "濃すぎる味付け"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .like,
            titles: [
               "カレー",
               "夜の散歩",
               "ボードゲーム",
               "キャンプ",
               "おすし",
               "温泉",
               "ハンバーグ",
               "朝のラジオ",
               "雨上がりの空",
               "サウナ",
               "海辺のドライブ",
               "ギター",
               "映画館",
               "コーヒー",
               "花火",
               "ラーメン",
               "唐揚げ",
               "昼寝",
               "登山",
               "クラフトビール",
               "深夜ラジオ"
            ],
            now: now
         ) +
         makeAppStoreScreenshotEntries(
            personID: appStoreScreenshotThirdPersonID,
            kind: .hate,
            titles: [
               "トマト",
               "雨の日の外出",
               "大きな音",
               "早起き",
               "満員電車",
               "強い香水",
               "長い行列",
               "虫",
               "辛すぎる料理",
               "狭い席",
               "ピーマン",
               "冷たい雨",
               "寝不足",
               "急な予定変更",
               "煙草のにおい",
               "待ち時間",
               "熱すぎる飲み物",
               "細かい作業",
               "寝坊",
               "渋滞",
               "薄いコーヒー",
               "予定の詰め込み",
               "湿気",
               "ぬるいお風呂",
               "パクチー",
               "明るすぎる照明",
               "通知音"
            ],
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
