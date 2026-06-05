import Foundation

struct PurchaseMessage: Identifiable {
   let id = UUID()
   let title: String
   let message: String
}

struct ReviewPrompt: Identifiable {
   let id = UUID()
   let title: String
   let message: String
}
