/// 買い切りプレミアムによる人数上限解除の判定ルール。
struct PremiumAccessPolicy: Hashable {
   /// 無料版で登録できる人物数。わたしを含める。
   static let freePersonLimit = 3

   /// 買い切りプレミアムが有効かどうか。
   var isPremium: Bool
   /// 旧広告非表示購入済みかどうか。
   var adsRemoved: Bool
   /// 現在登録されている人物数。
   var personCount: Int

   /// 人数制限解除・広告非表示として扱える状態かどうか。
   var hasPremiumAccess: Bool {
      isPremium || adsRemoved
   }

   /// 現在の人物数で新しく人物を追加できるかどうか。
   var canAddPerson: Bool {
      hasPremiumAccess || personCount < Self.freePersonLimit
   }
}
