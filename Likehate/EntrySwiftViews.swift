import FirebaseAnalytics
import GoogleMobileAds
import SwiftUI

struct ChooseEntrySwiftUIView: View {
   var body: some View {
      ZStack {
         VStack {
            HStack {
               LottieLoopView(name: "Egg")
                  .frame(width: 120, height: 120)
               Spacer()
               LottieLoopView(name: "MaruKuru")
                  .frame(width: 120, height: 120)
            }
            Spacer()
         }
         .padding()
         .allowsHitTesting(false)

         VStack(spacing: 18) {
            ForEach(EntryKind.allCases) { kind in
               NavigationLink {
                  WriteItemSwiftUIView(kind: kind)
               } label: {
                  VStack(alignment: .leading, spacing: 8) {
                     Text(kind.title)
                        .font(.largeTitle.bold())
                     Text(kind.prompt)
                        .font(.body)
                        .foregroundStyle(.secondary)
                  }
                  .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
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
      .navigationTitle(NSLocalizedString("register", comment: ""))
      .onAppear {
         HapticsClient.medium()
      }
   }
}

struct WriteItemSwiftUIView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @StateObject private var interstitialAd = LikehateInterstitialAdController()
   @State private var text = ""
   @State private var showEmptyAlert = false

   let kind: EntryKind

   var body: some View {
      ZStack {
         WriteLottieLayer(kind: kind)

         Form {
            Section {
               TextField(kind.prompt, text: $text)
                  .textInputAutocapitalization(.sentences)
                  .submitLabel(.done)
                  .onSubmit(save)
            } header: {
               Text(kind.prompt)
            }

            Section {
               Button(action: save) {
                  Label(NSLocalizedString("register", comment: ""), systemImage: "checkmark.circle.fill")
                     .frame(maxWidth: .infinity)
               }
               .buttonStyle(.borderedProminent)
               .tint(kind.color)
            }
         }
         .scrollContentBackground(.hidden)
      }
      .navigationTitle(kind.title)
      .alert("入力してください", isPresented: $showEmptyAlert) {
         Button("OK", role: .cancel) {}
      }
      .alert(item: $store.reviewPrompt) { prompt in
         Alert(
            title: Text(prompt.title),
            message: Text(prompt.message),
            primaryButton: .default(Text(NSLocalizedString("ThankYou", comment: ""))) {
               Analytics.logEvent("TapSCLAlertView", parameters: nil)
               AppReviewClient.requestReview()
            },
            secondaryButton: .cancel(Text(NSLocalizedString("Ohthankyou", comment: ""))) {
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

   var body: some View {
      GeometryReader { proxy in
         VStack {
            Spacer(minLength: proxy.size.height * 0.34)

            LottieLoopView(name: kind == .like ? "MoreHarts" : "Henka")
               .frame(width: proxy.size.width * 0.96, height: proxy.size.height * 0.52)
               .frame(maxWidth: .infinity)
               .padding(.horizontal, proxy.size.width * 0.02)
               .padding(.bottom, 15)
         }
      }
      .opacity(kind == .like ? 0.9 : 0.45)
      .allowsHitTesting(false)
   }
}

struct ItemListSwiftUIView: View {
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
