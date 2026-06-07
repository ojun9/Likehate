/// UserDefaultsなどから復元されるアプリ全体の設定値。
struct AppSettings: Codable, Hashable {
   /// Lottieなどのアニメーションを再生するかどうか。
   var animationEnabled: Bool
   /// 触覚フィードバックを鳴らすかどうか。
   var vibrationEnabled: Bool
   /// 旧広告非表示購入を含む広告非表示フラグ。
   var adsRemoved: Bool
   /// 買い切りプレミアムが有効かどうか。
   var isPremium: Bool
   /// アプリ独自の文字サイズ設定。
   var textSize: AppTextSize
   /// 現在のユーザーにオンボーディングを自動表示するかどうか。
   var showsOnboarding: Bool
}
