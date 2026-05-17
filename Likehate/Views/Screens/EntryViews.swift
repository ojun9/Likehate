import FirebaseAnalytics
import GoogleMobileAds
import SwiftUI

struct ChooseEntryView: View {
   @State private var showsLottie = false

   var body: some View {
      ZStack {
         VStack {
            if showsLottie {
               HStack {
                  LottieLoopView(name: "Egg")
                     .frame(width: 96, height: 96)
                  Spacer()
                  LottieLoopView(name: "MaruKuru")
                     .frame(width: 96, height: 96)
               }
            }
            Spacer()
         }
         .padding()
         .allowsHitTesting(false)

         VStack(spacing: 18) {
            ForEach(EntryKind.allCases) { kind in
               NavigationLink {
                  WriteItemView(kind: kind)
               } label: {
                  Text(kind.title)
                     .font(.largeTitle.bold())
                     .frame(maxWidth: .infinity, minHeight: 150)
                  .padding(20)
                  .background(kind.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                  .overlay(
                     RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(kind.color.opacity(0.35), lineWidth: 1)
                  )
               }
               .buttonStyle(.plain)
            }
         }
         .padding(20)
      }
      .navigationTitle("register")
      .onAppear {
         HapticsClient.medium()
      }
      .task {
         try? await Task.sleep(for: .milliseconds(350))
         showsLottie = true
      }
      .onDisappear {
         showsLottie = false
      }
   }
}

struct WriteItemView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @StateObject private var interstitialAd = LikehateInterstitialAdController()
   @State private var text = ""
   @State private var showEmptyAlert = false

   let kind: EntryKind

   var body: some View {
      GeometryReader { proxy in
         ZStack(alignment: .top) {
            Color(.systemBackground)
               .ignoresSafeArea()

            WriteLottieLayer(kind: kind, topOffset: 275)

            VStack(spacing: 0) {
               Text(kind.prompt)
                  .font(.system(size: 23))
                  .lineLimit(1)
                  .minimumScaleFactor(0.65)
                  .frame(maxWidth: .infinity)
                  .padding(.horizontal, 54)

               TextField(kind.prompt, text: $text)
                  .font(.system(size: 16, weight: .bold))
                  .textInputAutocapitalization(.sentences)
                  .submitLabel(.done)
                  .onSubmit(save)
                  .padding(.horizontal, 15)
                  .frame(height: 50)
                  .foregroundStyle(.primary)
                  .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                  .overlay(
                     RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.cyan, lineWidth: 2)
                  )
                  .padding(.top, kind == .like ? 43 : 34)
                  .padding(.horizontal, 54)

               Button(action: save) {
                  Text("register")
                     .frame(maxWidth: .infinity)
                     .frame(height: 74)
               }
               .buttonStyle(.borderedProminent)
               .tint(kind.color)
               .frame(width: min(proxy.size.width - 224, 160))
               .padding(.top, kind == .like ? 30 : 40)
            }
            .padding(.top, kind == .like ? 73 : 48)
         }
      }
      .navigationTitle(kind.title)
      .alert("入力してください", isPresented: $showEmptyAlert) {
         Button("OK", role: .cancel) {}
      }
      .alert(item: $store.reviewPrompt) { prompt in
         Alert(
            title: Text(prompt.title),
            message: Text(prompt.message),
            primaryButton: .default(Text("ThankYou")) {
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text("Ohthankyou")) {
               Analytics.logEvent("UserTap_OhThanks...For100", parameters: nil)
            }
         )
      }
      .onAppear {
         if kind == .hate && !store.didBuyRemoveAd {
            interstitialAd.load()
         }
      }
      .safeAreaInset(edge: .bottom) {
         if kind == .hate && !store.didBuyRemoveAd {
            LikehateAdaptiveAdBanner(adUnitID: AdMobUnitID.writeHateBanner)
         }
      }
   }

   private func save() {
      guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
         HapticsClient.error()
         showEmptyAlert = true
         return
      }

      store.add(text, to: kind)
      if kind == .hate && !store.didBuyRemoveAd {
         interstitialAd.present()
      }
      dismiss()
   }
}

struct WriteLottieLayer: View {
   let kind: EntryKind
   let topOffset: CGFloat

   var body: some View {
      GeometryReader { proxy in
         VStack {
            Spacer(minLength: topOffset)

            LottieLoopView(name: kind == .like ? "MoreHarts" : "Henka")
               .frame(width: proxy.size.width * 0.96, height: max(proxy.size.height - topOffset - 15, 120))
               .frame(maxWidth: .infinity)
               .padding(.horizontal, proxy.size.width * 0.02)
               .padding(.bottom, 15)
         }
      }
      .opacity(kind == .like ? 0.9 : 0.45)
      .allowsHitTesting(false)
   }
}

struct ItemListView: View {
   @EnvironmentObject private var store: LikeHateStore
   let kind: EntryKind

   var body: some View {
      List {
         ForEach(Array(store.items(for: kind).enumerated()), id: \.offset) { _, item in
            Text(item)
               .font(.title3)
               .lineLimit(2)
         }
         .onDelete { offsets in
            store.delete(at: offsets, from: kind)
         }
         .onMove { source, destination in
            store.move(from: source, to: destination, in: kind)
         }
      }
      .overlay {
         if store.items(for: kind).isEmpty {
            ContentUnavailableView(kind.listTitle, systemImage: "tray", description: Text("まだ登録されていません"))
         }
      }
      .navigationTitle(kind.listTitle)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            EditButton()
         }
      }
      .safeAreaInset(edge: .bottom) {
         if kind == .hate && !store.didBuyRemoveAd {
            LikehateAdaptiveAdBanner(adUnitID: AdMobUnitID.hateListBanner)
         }
      }
      .onAppear {
         Analytics.logEvent(kind == .like ? "showLikeTableView" : "showHateTableView", parameters: nil)
      }
   }
}
