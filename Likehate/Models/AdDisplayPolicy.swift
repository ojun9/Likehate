/// 広告表示の可否を判定するための小さなポリシー。
struct AdDisplayPolicy: Hashable {
   /// 旧広告非表示購入を含む広告非表示フラグ。
   var adsRemoved: Bool
   /// 買い切りプレミアムが有効かどうか。
   var isPremium: Bool = false

   /// アプリ全体として広告を表示してよい状態かどうか。
   var canShowAds: Bool {
      adsRemoved == false && isPremium == false
   }

   /// 一覧系画面で広告を表示してよいかを返す。
   func showsListAd(hasItems: Bool) -> Bool {
      canShowAds && hasItems
   }
}
