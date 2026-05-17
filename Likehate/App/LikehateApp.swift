import SwiftUI

@main
struct LikehateApp: App {
   @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
   @StateObject private var store = LikeHateStore()

   var body: some Scene {
      WindowGroup {
         RootView()
            .environmentObject(store)
      }
   }
}
