import SwiftUI

/// 好きか嫌いのどちらを登録するか選ぶ入口画面。
struct ChooseEntryView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @State private var showsLottie = false

   let personID: UUID?

   init(personID: UUID? = nil) {
      self.personID = personID
   }

   var body: some View {
      Group {
         if let person = selectedPerson {
            GeometryReader { proxy in
               ZStack(alignment: .top) {
                  VStack(spacing: 14) {
                     Text(verbatim: String.localizedStringWithFormat(String(localized: "EntryTargetFormat"), person.displayName))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                     ForEach(EntryKind.allCases) { kind in
                        NavigationLink {
                           WriteItemView(kind: kind, personID: person.id)
                        } label: {
                           VStack(spacing: 8) {
                              Text(verbatim: kind.title(for: person))
                                 .font(.largeTitle.bold())
                                 .fontDesign(.rounded)
                                 .lineLimit(1)
                                 .minimumScaleFactor(0.8)

                              Text(kind.selectionSubtitle)
                                 .font(.callout.weight(.medium))
                                 .fontDesign(.rounded)
                                 .foregroundStyle(.secondary)
                                 .lineLimit(1)
                                 .minimumScaleFactor(0.75)
                           }
                           .frame(maxWidth: .infinity, minHeight: 132)
                           .padding(.horizontal, 20)
                           .padding(.vertical, 16)
                           .background(LikehateTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                           .overlay(
                              RoundedRectangle(cornerRadius: 22, style: .continuous)
                                 .stroke(kind.color.opacity(colorScheme == .dark ? 0.2 : 0.14), lineWidth: 1)
                           )
                           .overlay(alignment: kind == .like ? .leading : .trailing) {
                              if store.animationEnabled && showsLottie {
                                 LottieLoopView(name: kind == .like ? "Egg" : "MaruKuru")
                                    .opacity(0.42)
                                    .frame(width: 96, height: 96)
                                    .clipped()
                                    .padding(.horizontal, 12)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                              }
                           }
                           .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 12, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                           FAAnalytics.log(.track(.chooseEntryKindTapped, parameters: [
                              .kind: kind.rawValue,
                              .personID: person.id.uuidString,
                              .isMe: person.isMe
                           ]))
                        })
                     }
                  }
                  .padding(.horizontal, 20)
                  .padding(.top, max(proxy.safeAreaInsets.top + 18, 32))
               }
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle("ChooseEntryTitle")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
         FAAnalytics.log(.screenView(.chooseEntry, parameters: chooseAnalyticsParameters))
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

   private var selectedPerson: Person? {
      if let personID {
         return store.person(for: personID)
      }
      return store.mePerson
   }

   private var chooseAnalyticsParameters: FAParameters {
      var parameters: FAParameters = [
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .animationEnabled: store.animationEnabled
      ]

      if let selectedPerson {
         parameters[.personID] = selectedPerson.id.uuidString
         parameters[.isMe] = selectedPerson.isMe
      }

      return parameters
   }
}
