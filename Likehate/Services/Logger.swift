import Foundation
import os

/// OSLogのカテゴリをまとめる名前空間。
enum Logger: Sendable {
  /// 通常のアプリログ。
  static let standard: os.Logger = makeLogger(category: "Standard")
  /// AnalyticsのDEBUG確認ログ。
  static let analytics: os.Logger = makeLogger(category: "Analytics")
  /// 課金処理のDEBUG確認ログ。
  static let purchases: os.Logger = makeLogger(category: "Purchases")

  /// アプリのbundle identifierをsubsystemにしたLoggerを作る。
  static func makeLogger(category: String) -> os.Logger {
    .init(
      subsystem: Bundle.main.bundleIdentifier!,
      category: category
    )
  }
}
