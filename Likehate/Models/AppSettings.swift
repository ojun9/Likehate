struct AppSettings: Codable, Hashable {
   var animationEnabled: Bool
   var vibrationEnabled: Bool
   var adsRemoved: Bool
   var isPremium: Bool
   var textSize: AppTextSize
}
