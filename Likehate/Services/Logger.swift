import Foundation
import os

enum Logger: Sendable {
  static let standard: os.Logger = makeLogger(category: "Standard")
  static let analytics: os.Logger = makeLogger(category: "Analytics")

  static func makeLogger(category: String) -> os.Logger {
    .init(
      subsystem: Bundle.main.bundleIdentifier!,
      category: category
    )
  }
}
