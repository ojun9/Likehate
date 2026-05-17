import SwiftUI

enum EntryKind: String, CaseIterable, Identifiable {
   case like
   case hate

   var id: String { rawValue }

   var title: String {
      switch self {
      case .like: return NSLocalizedString("Like", comment: "")
      case .hate: return NSLocalizedString("Hate", comment: "")
      }
   }

   var listTitle: String {
      switch self {
      case .like: return NSLocalizedString("likething", comment: "")
      case .hate: return NSLocalizedString("hatething", comment: "")
      }
   }

   var prompt: String {
      switch self {
      case .like: return NSLocalizedString("WhatLike", comment: "")
      case .hate: return NSLocalizedString("WhatHate", comment: "")
      }
   }

   var storageKey: String {
      switch self {
      case .like: return "OpenLikeKey"
      case .hate: return "OpenHateKey"
      }
   }

   var color: Color {
      switch self {
      case .like: return Color(red: 0.957, green: 0.275, blue: 0.365)
      case .hate: return Color(red: 0.353, green: 0.737, blue: 0.816)
      }
   }

   var analyticsName: String {
      switch self {
      case .like: return "RegiLike"
      case .hate: return "RegiHate"
      }
   }
}

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
