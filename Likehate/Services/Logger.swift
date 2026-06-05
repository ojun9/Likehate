import Foundation
import os

enum Logger: Sendable {
  static let standard: os.Logger = makeLogger(category: "Standard")
  static let analytics: os.Logger = makeLogger(category: "Analytics")
  static let firestore: os.Logger = makeLogger(category: "Firestore")
  static let notification: os.Logger = makeLogger(category: "Notification")

  static func makeLogger(category: String) -> os.Logger {
    .init(
      subsystem: Bundle.main.bundleIdentifier!,
      category: category
    )
  }
}
