import SwiftUI

/// アプリのエントリポイント。共有ストアを生成してルート画面へ注入する。
@main
struct LikehateApp: App {
   @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
   @StateObject private var store = LikeHateStore()
   @State private var didRecordLaunch = false

   var body: some Scene {
      WindowGroup {
         RootView()
            .environmentObject(store)
            .onAppear {
               guard !didRecordLaunch else { return }
               didRecordLaunch = true
               store.refreshPremiumStatus()
               store.recordLaunchAndRequestReviewIfNeeded()
            }
      }
   }
}
