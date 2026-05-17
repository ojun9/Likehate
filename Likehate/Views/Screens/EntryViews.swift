import FirebaseAnalytics
import SwiftUI

struct ChooseEntryView: View {
   @State private var showsLottie = false

   var body: some View {
      GeometryReader { proxy in
         ZStack(alignment: .top) {
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

            VStack(spacing: 14) {
               ForEach(EntryKind.allCases) { kind in
                  NavigationLink {
                     WriteItemView(kind: kind)
                  } label: {
                     VStack(spacing: 8) {
                        Text(kind.title)
                           .font(.system(.largeTitle, design: .rounded, weight: .bold))
                           .lineLimit(1)
                           .minimumScaleFactor(0.8)

                        Text(kind.selectionSubtitle)
                           .font(.system(.callout, design: .rounded, weight: .medium))
                           .foregroundStyle(.secondary)
                           .lineLimit(1)
                           .minimumScaleFactor(0.75)
                     }
                     .frame(maxWidth: .infinity, minHeight: 132)
                     .padding(.horizontal, 20)
                     .padding(.vertical, 16)
                     .background(kind.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                     .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                           .stroke(kind.color.opacity(0.28), lineWidth: 1)
                     )
                     .shadow(color: kind.color.opacity(0.08), radius: 8, x: 0, y: 2)
                  }
                  .buttonStyle(.plain)
               }
            }
            .padding(.horizontal, 20)
            .padding(.top, max(proxy.safeAreaInsets.top + 18, 32))
         }
      }
      .navigationTitle("登録")
      .navigationBarTitleDisplayMode(.inline)
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
   @State private var text = ""
   @State private var showEmptyAlert = false
   @FocusState private var isTextFieldFocused: Bool

   let kind: EntryKind

   var body: some View {
      GeometryReader { proxy in
         ZStack(alignment: .top) {
            Color(.systemBackground)
               .ignoresSafeArea()

            WriteLottieLayer(kind: kind, topOffset: kind == .like ? 250 : 270)

            VStack(spacing: 0) {
               Text(kind.prompt)
                  .font(.system(.title3, design: .rounded, weight: .semibold))
                  .lineLimit(1)
                  .minimumScaleFactor(0.65)
                  .frame(maxWidth: .infinity)
                  .padding(.horizontal, 34)

               TextField(kind.prompt, text: $text)
                  .font(.system(.body, design: .rounded, weight: .semibold))
                  .textInputAutocapitalization(.sentences)
                  .submitLabel(.done)
                  .onSubmit(save)
                  .focused($isTextFieldFocused)
                  .padding(.horizontal, 16)
                  .frame(minHeight: 52)
                  .foregroundStyle(.primary)
                  .background(fieldBackgroundColor, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                  .overlay(
                     RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(fieldBorderColor, lineWidth: isTextFieldFocused ? 1.5 : 1)
                  )
                  .shadow(color: kind.color.opacity(isTextFieldFocused ? 0.14 : 0.06), radius: isTextFieldFocused ? 8 : 4, x: 0, y: 2)
                  .padding(.top, kind == .like ? 34 : 28)
                  .padding(.horizontal, 36)

               Button(action: save) {
                  Text("register")
                     .font(.system(.body, design: .rounded, weight: .bold))
                     .frame(maxWidth: .infinity)
                     .frame(height: 56)
               }
               .buttonStyle(.borderedProminent)
               .tint(kind.color)
               .frame(width: registerButtonWidth(for: proxy.size.width))
               .clipShape(Capsule())
               .controlSize(.regular)
               .padding(.top, kind == .like ? 24 : 30)
            }
            .padding(.top, kind == .like ? 58 : 44)
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
   }

   private func save() {
      guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
         HapticsClient.error()
         showEmptyAlert = true
         return
      }

      store.add(text, to: kind)
      dismiss()
   }

   private func registerButtonWidth(for containerWidth: CGFloat) -> CGFloat {
      let availableWidth = min(containerWidth * 0.34, 140)
      guard availableWidth.isFinite else { return 0 }
      return max(116, availableWidth)
   }

   private var fieldBackgroundColor: Color {
      kind.color.opacity(isTextFieldFocused ? 0.12 : 0.07)
   }

   private var fieldBorderColor: Color {
      kind.color.opacity(isTextFieldFocused ? 0.48 : 0.2)
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
      .opacity(kind == .like ? 0.72 : 0.32)
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
               .font(.system(.body, design: .rounded))
               .lineLimit(2)
               .padding(.vertical, 4)
               .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
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
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            EditButton()
               .font(.subheadline)
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
