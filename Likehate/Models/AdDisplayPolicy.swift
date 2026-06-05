struct AdDisplayPolicy: Hashable {
   var adsRemoved: Bool
   var isPremium: Bool = false

   var canShowAds: Bool {
      adsRemoved == false && isPremium == false
   }

   func showsListAd(hasItems: Bool) -> Bool {
      canShowAds && hasItems
   }
}
