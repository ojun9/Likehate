import SwiftUI

enum EntryKind: String, CaseIterable, Identifiable, Codable {
   case like
   case hate

   var id: String { rawValue }

   var title: String {
      switch self {
      case .like: return String(localized: "Like")
      case .hate: return String(localized: "Hate")
      }
   }

   func title(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, _):
         return String(localized: "Like")
      case (.hate, _):
         return String(localized: "Hate")
      }
   }

   var selectionSubtitle: String {
      switch self {
      case .like: return String(localized: "LikeSelectionSubtitle")
      case .hate: return String(localized: "HateSelectionSubtitle")
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

   var inputPlaceholder: String {
      switch self {
      case .like: return String(localized: "LikeInputPlaceholder")
      case .hate: return String(localized: "HateInputPlaceholder")
      }
   }

   func inputPlaceholder(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "LikeInputPlaceholder"
      case (.hate, _):
         return "HateInputPlaceholder"
      }
   }

   var inputButtonTitle: String {
      switch self {
      case .like: return String(localized: "LikeInputButton")
      case .hate: return String(localized: "HateInputButton")
      }
   }

   func inputButtonTitle(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, true):
         return String(localized: "LikeInputButtonMe")
      case (.like, false):
         return String.localizedStringWithFormat(String(localized: "LikeInputButtonPersonFormat"), person.displayName)
      case (.hate, true):
         return String(localized: "HateInputButtonMe")
      case (.hate, false):
         return String.localizedStringWithFormat(String(localized: "HateInputButtonPersonFormat"), person.displayName)
      }
   }

   func listTitle(for person: Person) -> String {
      switch (self, person.isMe) {
      case (.like, true):
         return String(localized: "MyLikesTitle")
      case (.like, false):
         return String.localizedStringWithFormat(String(localized: "PersonLikesTitleFormat"), person.displayName)
      case (.hate, true):
         return String(localized: "MyHatesTitle")
      case (.hate, false):
         return String.localizedStringWithFormat(String(localized: "PersonHatesTitleFormat"), person.displayName)
      }
   }

   func emptyListTitle(for person: Person) -> LocalizedStringKey {
      switch (self, person.isMe) {
      case (.like, _):
         return "EmptyLikesTitle"
      case (.hate, _):
         return "EmptyHatesTitle"
      }
   }

   func emptyListMessage(for person: Person) -> LocalizedStringKey {
      switch self {
      case .like: return "EmptyLikesMessage"
      case .hate: return "EmptyHatesMessage"
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
      case .like: return LikehateTheme.likeAccent
      case .hate: return LikehateTheme.hateAccent
      }
   }

   var analyticsName: String {
      switch self {
      case .like: return "RegiLike"
      case .hate: return "RegiHate"
      }
   }
}

struct Person: Identifiable, Codable, Hashable {
   var id: UUID
   var name: String
   var profileImageName: String?
   var photoFileName: String?
   var isMe: Bool
   var createdAt: Date
   var updatedAt: Date
   var sortOrder: Int

   var displayName: String {
      let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
      if isMe {
         if trimmedName.isEmpty || trimmedName == "自分" {
            return String(localized: "DefaultMeName")
         }
         return trimmedName
      }

      return trimmedName.isEmpty ? name : trimmedName
   }

   var profileImage: DefaultProfileImage {
      get { DefaultProfileImage(rawValue: profileImageName ?? "") ?? .defaultProfileImage }
      set { profileImageName = newValue.rawValue }
   }
}

enum DefaultProfileImage: String, CaseIterable, Identifiable, Codable, Hashable {
   case defaultProfileImage
   case defaultProfileImage2
   case defaultProfileImage3
   case defaultProfileImage4
   case defaultProfileImage5
   case defaultProfileImage6
   case defaultProfileImage7
   case defaultProfileImage8
   case defaultProfileImage9
   case defaultProfileImage10
   case defaultProfileImage11
   case defaultProfileImage12
   case defaultProfileImage13
   case defaultProfileImage14
   case defaultProfileImage15
   case defaultProfileImage16
   case defaultProfileImage17
   case defaultProfileImage18
   case defaultProfileImage19

   var id: String { rawValue }

   var assetName: String { rawValue }

   var optionNumber: Int {
      Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 1
   }

   static func firstAvailable(excluding usedImages: Set<DefaultProfileImage>) -> DefaultProfileImage {
      allCases.first { !usedImages.contains($0) } ?? .defaultProfileImage
   }

   static func random() -> DefaultProfileImage {
      allCases.randomElement() ?? .defaultProfileImage
   }
}

enum PersonNameRules {
   static let maxLength = 40

   static func limited(_ name: String) -> String {
      String(name.prefix(maxLength))
   }

   static func sanitized(_ rawName: String) -> String {
      let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
      return limited(trimmedName)
   }
}

struct LikeDislikeItem: Identifiable, Codable, Hashable {
   var id: UUID
   var personId: UUID
   var type: EntryKind
   var title: String
   var note: String?
   var createdAt: Date
   var updatedAt: Date
   var sortOrder: Int
}

enum EntryPreviewItems {
   static let maxCount = 2

   static func items(from items: [LikeDislikeItem], limit: Int = maxCount) -> [LikeDislikeItem] {
      guard limit > 0 else { return [] }
      return Array(items.prefix(limit))
   }
}

enum EntryLottieSelection {
   static let likeNames = ["MoreHarts", "heart1", "heart2"]
   static let hateNames = ["fish", "lightiing", "wave", "Bubbles", "Bubbles2", "Bubbbles3"]

   static func names(for kind: EntryKind) -> [String] {
      switch kind {
      case .like: return likeNames
      case .hate: return hateNames
      }
   }

   static func randomName(for kind: EntryKind, excluding currentName: String? = nil) -> String {
      let names = names(for: kind)
      let candidates = names.filter { $0 != currentName }
      return (candidates.isEmpty ? names : candidates).randomElement() ?? fallbackName(for: kind)
   }

   static func fallbackName(for kind: EntryKind) -> String {
      names(for: kind).first ?? ""
   }
}

struct AppSettings: Codable, Hashable {
   var animationEnabled: Bool
   var vibrationEnabled: Bool
   var adsRemoved: Bool
   var textSize: AppTextSize
}

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

enum AppTextSize: String, CaseIterable, Codable, Hashable, Identifiable {
   case extraSmall
   case small
   case standard
   case large
   case extraLarge

   var id: String { rawValue }

   func advanced(by offset: Int) -> AppTextSize {
      let allSizes = Self.allCases
      guard let currentIndex = allSizes.firstIndex(of: self) else { return self }
      let clampedIndex = min(max(currentIndex + offset, 0), allSizes.count - 1)
      return allSizes[clampedIndex]
   }

   var title: LocalizedStringKey {
      switch self {
      case .extraSmall: return "TextSizeExtraSmall"
      case .small: return "TextSizeSmall"
      case .standard: return "TextSizeStandard"
      case .large: return "TextSizeLarge"
      case .extraLarge: return "TextSizeExtraLarge"
      }
   }
}

enum ComparisonCategory: String, CaseIterable, Identifiable {
   case firstOnlyLike
   case commonLike
   case secondOnlyLike
   case firstOnlyHate
   case commonHate
   case secondOnlyHate

   var id: String { rawValue }

   var kind: EntryKind {
      switch self {
      case .firstOnlyLike, .commonLike, .secondOnlyLike:
         return .like
      case .firstOnlyHate, .commonHate, .secondOnlyHate:
         return .hate
      }
   }

   var color: Color {
      switch self {
      case .commonLike:
         return EntryKind.like.color.opacity(0.22)
      case .firstOnlyLike, .secondOnlyLike:
         return EntryKind.like.color.opacity(0.12)
      case .commonHate:
         return EntryKind.hate.color.opacity(0.24)
      case .firstOnlyHate, .secondOnlyHate:
         return EntryKind.hate.color.opacity(0.13)
      }
   }

   var borderColor: Color {
      switch self {
      case .firstOnlyLike, .commonLike, .secondOnlyLike:
         return EntryKind.like.color.opacity(0.32)
      case .firstOnlyHate, .commonHate, .secondOnlyHate:
         return EntryKind.hate.color.opacity(0.34)
      }
   }

   func title(first: Person, second: Person) -> String {
      switch self {
      case .firstOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonFirstOnlyLikeFormat"), first.displayName)
      case .commonLike:
         return String(localized: "ComparisonCommonLike")
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonSecondOnlyLikeFormat"), second.displayName)
      case .firstOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonFirstOnlyHateFormat"), first.displayName)
      case .commonHate:
         return String(localized: "ComparisonCommonHate")
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonSecondOnlyHateFormat"), second.displayName)
      }
   }
}

struct ComparisonSection: Identifiable, Hashable {
   let category: ComparisonCategory
   let titles: [String]

   var id: ComparisonCategory { category }
}

struct ComparisonResultSectionGroup: Identifiable, Hashable {
   enum GroupID: String, CaseIterable {
      case together
      case avoid
      case differences
   }

   let id: GroupID
   let titleKey: String
   let categories: [ComparisonCategory]

   static let ordered: [ComparisonResultSectionGroup] = [
      ComparisonResultSectionGroup(
         id: .together,
         titleKey: "ComparisonTogetherTitle",
         categories: [.commonLike]
      ),
      ComparisonResultSectionGroup(
         id: .avoid,
         titleKey: "ComparisonAvoidTitle",
         categories: [.commonHate]
      ),
      ComparisonResultSectionGroup(
         id: .differences,
         titleKey: "ComparisonDifferencesTitle",
         categories: [.firstOnlyLike, .secondOnlyLike, .firstOnlyHate, .secondOnlyHate]
      )
   ]

   func sections(from sections: [ComparisonSection]) -> [ComparisonSection] {
      sections.filter { categories.contains($0.category) }
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
