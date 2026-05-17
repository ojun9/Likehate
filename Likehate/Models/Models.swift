import SwiftUI

enum EntryKind: String, CaseIterable, Identifiable {
   case like
   case hate

   var id: String { rawValue }

   var title: String {
      switch self {
      case .like: return String(localized: "Like")
      case .hate: return String(localized: "Hate")
      }
   }

   var selectionSubtitle: String {
      switch self {
      case .like: return "残しておきたいもの"
      case .hate: return "忘れずに避けたいもの"
      }
   }

   var listTitle: String {
      switch self {
      case .like: return String(localized: "likething")
      case .hate: return String(localized: "hatething")
      }
   }

   var prompt: String {
      switch self {
      case .like: return String(localized: "WhatLike")
      case .hate: return String(localized: "WhatHate")
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
