struct PremiumAccessPolicy: Hashable {
   static let freePersonLimit = 3

   var isPremium: Bool
   var adsRemoved: Bool
   var personCount: Int

   var hasPremiumAccess: Bool {
      isPremium || adsRemoved
   }

   var canAddPerson: Bool {
      hasPremiumAccess || personCount < Self.freePersonLimit
   }
}
