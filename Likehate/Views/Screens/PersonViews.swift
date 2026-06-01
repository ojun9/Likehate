import FirebaseAnalytics
import PhotosUI
import SwiftUI
import UIKit

enum PersonSelectionMode {
   case register
   case browse

   var title: LocalizedStringKey {
      switch self {
      case .register: return "ChoosePersonForEntryTitle"
      case .browse: return "ChoosePersonToBrowseTitle"
      }
   }
}

struct PersonSelectionView: View {
   @EnvironmentObject private var store: LikeHateStore
   @State private var formMode: PersonFormMode?

   let mode: PersonSelectionMode

   var body: some View {
      List {
         Section {
            ForEach(store.persons) { person in
               NavigationLink {
                  destination(for: person)
               } label: {
                  PersonSummaryRow(person: person)
               }
               .contextMenu {
                  Button {
                     formMode = .edit(person)
                  } label: {
                     Label("EditPersonButton", systemImage: "pencil")
                  }
               }
               .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button {
                     formMode = .edit(person)
                  } label: {
                     Label("EditPersonButton", systemImage: "pencil")
                  }
                  .tint(.blue)
               }
            }
         }
      }
      .navigationTitle(mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .topBarTrailing) {
            Button {
               formMode = .add
            } label: {
               Image(systemName: "plus")
            }
            .accessibilityLabel(Text("AddPersonButton"))
         }
      }
      .sheet(item: $formMode) { formMode in
         NavigationStack {
            PersonFormView(mode: formMode)
         }
      }
      .onAppear {
         Analytics.logEvent("screen_view_person_selection", parameters: [
            "mode": mode == .register ? "register" : "browse",
            "person_count": store.persons.count,
            "entry_count": store.totalItemCount
         ])
      }
   }

   @ViewBuilder
   private func destination(for person: Person) -> some View {
      switch mode {
      case .register:
         ChooseEntryView(personID: person.id)
      case .browse:
         PersonDetailView(personID: person.id)
      }
   }
}

struct PersonSummaryRow: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let likeCount = store.items(for: person.id, kind: .like).count
      let hateCount = store.items(for: person.id, kind: .hate).count
      let countFormat = String(localized: "PersonCountFormat")
      let countText = String.localizedStringWithFormat(countFormat, likeCount, hateCount)

      HStack(spacing: 12) {
         PersonAvatar(person: person)

         VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
               Text(verbatim: person.displayName)
                  .font(typography.body)
                  .foregroundStyle(.primary)
                  .lineLimit(1)
            }

            Text(verbatim: countText)
               .font(typography.subtext)
               .foregroundStyle(.secondary)
         }
      }
      .padding(.vertical, 5)
      .accessibilityElement(children: .combine)
   }
}

struct PersonAvatar: View {
   @EnvironmentObject private var store: LikeHateStore

   let person: Person
   var size: CGFloat = 38

   var body: some View {
      PersonAvatarContent(
         image: store.photoImage(for: person),
         profileImage: person.profileImage,
         size: size
      )
   }
}

private struct PersonAvatarContent: View {
   let image: UIImage?
   let profileImage: DefaultProfileImage
   let size: CGFloat

   var body: some View {
      avatarImage
         .resizable()
         .scaledToFill()
         .frame(width: size, height: size)
         .clipShape(Circle())
         .overlay {
            Circle()
               .stroke(.white.opacity(0.16), lineWidth: 1)
         }
         .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
   }

   private var avatarImage: Image {
      if let image {
         return Image(uiImage: image)
      }
      return Image(profileImage.assetName)
   }
}

enum PersonFormMode: Identifiable {
   case add
   case edit(Person)

   var id: String {
      switch self {
      case .add:
         return "add"
      case .edit(let person):
         return person.id.uuidString
      }
   }

   var title: LocalizedStringKey {
      switch self {
      case .add: return "AddPersonTitle"
      case .edit: return "EditPersonTitle"
      }
   }

   var saveTitle: LocalizedStringKey {
      switch self {
      case .add: return "AddPersonSaveButton"
      case .edit: return "SavePersonButton"
      }
   }
}

struct PersonFormView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var name: String
   @State private var selectedProfileImage: DefaultProfileImage
   @State private var selectedPhotoItem: PhotosPickerItem?
   @State private var selectedPhotoData: Data?
   @State private var selectedPhotoPreview: UIImage?
   @State private var cropSourceImage: PersonPhotoCropSource?
   @State private var removesExistingPhoto = false
   @State private var isLoadingPhoto = false
   @State private var isShowingDeleteConfirmation = false
   @FocusState private var isNameFocused: Bool

   let mode: PersonFormMode
   var onAdd: ((Person) -> Void)?

   init(mode: PersonFormMode, onAdd: ((Person) -> Void)? = nil) {
      self.mode = mode
      self.onAdd = onAdd
      switch mode {
      case .add:
         _name = State(initialValue: "")
         _selectedProfileImage = State(initialValue: .random())
      case .edit(let person):
         _name = State(initialValue: person.displayName)
         _selectedProfileImage = State(initialValue: person.profileImage)
      }
   }

   var body: some View {
      let currentPhotoButtonTitle = photoButtonTitle
      let typography = store.typography(for: dynamicTypeSize)

      Form {
         Section {
            VStack(spacing: 12) {
               PersonAvatarContent(
                  image: previewImage,
                  profileImage: selectedProfileImage,
                  size: 84
               )

               PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                  Label(currentPhotoButtonTitle, systemImage: "photo")
                     .font(typography.button)
                     .foregroundStyle(LikehateTheme.likeAccent)
               }
               .disabled(isLoadingPhoto)

               if canRemovePhoto {
                  Button(role: .destructive) {
                     removePhoto()
                  } label: {
                     Label("DeletePersonPhotoButton", systemImage: "xmark.circle")
                        .font(typography.button)
                  }
               }

               if isLoadingPhoto {
                  ProgressView("LoadingPersonPhoto")
                     .font(typography.subtext)
               }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
         }

         Section {
            if isEditingMe {
               Text("DefaultMeName")
                  .font(typography.body)
                  .foregroundStyle(.secondary)
            } else {
               TextField("PersonNamePlaceholder", text: $name)
                  .font(typography.bodyRegular)
                  .textInputAutocapitalization(.words)
                  .autocorrectionDisabled()
                  .focused($isNameFocused)
                  .submitLabel(.done)
                  .onSubmit {
                     save()
                  }
                  .onChange(of: name) { _, newValue in
                     if newValue.count > 30 {
                        name = String(newValue.prefix(30))
                     }
                  }
            }
         } footer: {
            if case .add = mode {
               Text("AddPersonHelpText")
            }
         }

         Section("ProfileImageSectionTitle") {
            DefaultProfileImagePicker(selectedProfileImage: $selectedProfileImage)
         }

         if case .edit(let person) = mode, !person.isMe {
            Section {
               Button(role: .destructive) {
                  isShowingDeleteConfirmation = true
               } label: {
                  Text("DeletePersonButton")
               }
            }
         }
      }
      .scrollContentBackground(.hidden)
      .background(LikehateTheme.background)
      .navigationTitle(mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
         ToolbarItem(placement: .cancellationAction) {
            Button("cancel") {
               dismiss()
            }
         }

         ToolbarItem(placement: .confirmationAction) {
            Button(mode.saveTitle) {
               save()
            }
            .disabled(isLoadingPhoto || (!isEditingMe && trimmedName.isEmpty))
         }
      }
      .confirmationDialog(
         String(localized: "DeletePersonConfirmationTitle"),
         isPresented: $isShowingDeleteConfirmation,
         titleVisibility: .visible
      ) {
         Button(String(localized: "DeletePersonConfirmButton"), role: .destructive) {
            if case .edit(let person) = mode {
               store.deletePerson(person.id)
            }
            dismiss()
         }
         Button(String(localized: "cancel"), role: .cancel) {}
      } message: {
         Text("DeletePersonConfirmationMessage")
      }
      .sheet(item: $cropSourceImage) { source in
         PersonPhotoCropView(sourceImage: source.image) { croppedImage in
            finishCropping(image: croppedImage)
         } onCancel: {
            cropSourceImage = nil
         }
      }
      .onAppear {
         if case .add = mode {
            isNameFocused = true
         }
      }
      .onChange(of: selectedPhotoItem) { _, item in
         Task {
            await loadPhoto(from: item)
         }
      }
   }

   private var trimmedName: String {
      name.trimmingCharacters(in: .whitespacesAndNewlines)
   }

   private var previewImage: UIImage? {
      if let selectedPhotoPreview {
         return selectedPhotoPreview
      }

      guard !removesExistingPhoto else { return nil }
      if case .edit(let person) = mode {
         return store.photoImage(for: person)
      }
      return nil
   }

   private var canRemovePhoto: Bool {
      previewImage != nil
   }

   private var photoButtonTitle: String {
      String(localized: canRemovePhoto ? "ChangePersonPhotoButton" : "SelectPersonPhotoButton")
   }

   private var isEditingMe: Bool {
      if case .edit(let person) = mode {
         return person.isMe
      }
      return false
   }

   private func save() {
      guard isEditingMe || !trimmedName.isEmpty else { return }

      switch mode {
      case .add:
         if let person = store.addPerson(named: name, profileImage: selectedProfileImage, photoData: selectedPhotoData) {
            onAdd?(person)
         }
      case .edit(let person):
         store.updatePerson(
            person.id,
            name: name,
            profileImage: selectedProfileImage,
            photoData: selectedPhotoData,
            removesPhoto: removesExistingPhoto
         )
      }

      dismiss()
   }

   @MainActor
   private func loadPhoto(from item: PhotosPickerItem?) async {
      guard let item else { return }
      isLoadingPhoto = true
      defer {
         isLoadingPhoto = false
         selectedPhotoItem = nil
      }

      do {
         guard
            let data = try await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
         else {
            return
         }

         cropSourceImage = PersonPhotoCropSource(image: image)
      } catch {
         selectedPhotoData = nil
         selectedPhotoPreview = nil
      }
   }

   private func finishCropping(image: UIImage) {
      let imageData = image.pngData() ?? image.jpegData(compressionQuality: 0.92)
      guard
         let imageData,
         let thumbnailData = LikeHateStore.thumbnailPhotoData(from: imageData),
         let thumbnail = UIImage(data: thumbnailData)
      else {
         cropSourceImage = nil
         return
      }

      selectedPhotoData = thumbnailData
      selectedPhotoPreview = thumbnail
      removesExistingPhoto = false
      cropSourceImage = nil
   }

   private func removePhoto() {
      selectedPhotoItem = nil
      selectedPhotoData = nil
      selectedPhotoPreview = nil
      cropSourceImage = nil
      if case .edit = mode {
         removesExistingPhoto = true
      }
   }
}

private struct DefaultProfileImagePicker: View {
   @Binding var selectedProfileImage: DefaultProfileImage

   private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

   var body: some View {
      LazyVGrid(columns: columns, spacing: 12) {
         ForEach(DefaultProfileImage.allCases) { profileImage in
            Button {
               selectedProfileImage = profileImage
            } label: {
               let isSelected = selectedProfileImage == profileImage

               Image(profileImage.assetName)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 58, height: 58)
                  .clipShape(Circle())
                  .overlay {
                     Circle()
                        .stroke(isSelected ? LikehateTheme.likeAccent : LikehateTheme.border, lineWidth: isSelected ? 2 : 1)
                  }
                  .overlay(alignment: .bottomTrailing) {
                     if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                           .font(.caption.weight(.bold))
                           .foregroundStyle(.white, LikehateTheme.likeAccent)
                           .background(.white, in: Circle())
                           .offset(x: 2, y: 2)
                     }
                  }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: String.localizedStringWithFormat(String(localized: "ProfileImageOptionFormat"), profileImage.optionNumber)))
            .accessibilityAddTraits(selectedProfileImage == profileImage ? .isSelected : [])
         }
      }
      .padding(.vertical, 4)
   }
}

struct PersonDetailView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var formMode: PersonFormMode?

   let personID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if let person = store.person(for: personID) {
            ScrollView {
               VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                  HStack(spacing: 12) {
                     PersonAvatar(person: person, size: 52)

                     Text(verbatim: person.displayName)
                        .font(typography.screenTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                  }
                  .padding(.top, 8)

                  PersonEntryPreviewSection(person: person, kind: .like)
                  PersonEntryPreviewSection(person: person, kind: .hate)

                  comparisonLink(for: person)
               }
               .padding(.horizontal, layout.screenPadding)
               .padding(.vertical, layout.cardSpacing)
            }
            .background(LikehateTheme.background)
            .navigationTitle(person.displayName)
            .toolbar {
               ToolbarItem(placement: .topBarTrailing) {
                  Button {
                     formMode = .edit(person)
                  } label: {
                     Image(systemName: "pencil")
                  }
                  .accessibilityLabel(Text("EditPersonButton"))
               }
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationBarTitleDisplayMode(.inline)
      .sheet(item: $formMode) { formMode in
         NavigationStack {
            PersonFormView(mode: formMode)
         }
      }
      .onAppear {
         Analytics.logEvent("screen_view_person_detail", parameters: [
            "person_id": personID.uuidString,
            "person_count": store.persons.count,
            "entry_count": store.totalItemCount
         ])
      }
   }

   @ViewBuilder
   private func comparisonLink(for person: Person) -> some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      if let mePerson = store.mePerson, mePerson.id != person.id {
         NavigationLink {
            ComparisonResultView(firstPersonID: mePerson.id, secondPersonID: person.id)
         } label: {
            HStack {
               Text(verbatim: String.localizedStringWithFormat(String(localized: "CompareWithPersonFormat"), person.displayName))
                  .font(typography.button)
                  .foregroundStyle(.primary)
                  .lineLimit(2)

               Spacer()

               Image(systemName: "chevron.right")
                  .font(typography.subtext)
                  .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
            .frame(minHeight: max(56, layout.rowMinHeight), alignment: .leading)
         }
         .buttonStyle(.plain)
      } else {
         NavigationLink {
            ComparisonSelectionView()
         } label: {
            HStack {
               Text("CompareWithSomeoneButton")
                  .font(typography.button)
                  .foregroundStyle(.primary)

               Spacer()

               Image(systemName: "chevron.right")
                  .font(typography.subtext)
                  .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
            .frame(minHeight: max(56, layout.rowMinHeight), alignment: .leading)
         }
         .buttonStyle(.plain)
      }
   }
}

private struct PersonEntryPreviewSection: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let person: Person
   let kind: EntryKind

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics
      let items = store.items(for: person.id, kind: kind)
      let previewItems = Array(items.suffix(3).reversed())
      let countText = String.localizedStringWithFormat(String(localized: "ItemsCountFormat"), items.count)

      VStack(alignment: .leading, spacing: 16) {
         HStack {
            Text(verbatim: kind.title(for: person))
               .font(typography.sectionTitle)
            Spacer()
            Text(verbatim: countText)
               .font(typography.count)
               .foregroundStyle(.secondary)
         }

         if previewItems.isEmpty {
            Text(kind.emptyListTitle(for: person))
               .font(typography.body)
               .foregroundStyle(.secondary)
               .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)
         } else {
            VStack(spacing: 0) {
               ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                  Text(verbatim: item.title)
                     .font(typography.body)
                     .lineLimit(2)
                     .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)

                  if index < previewItems.count - 1 {
                     Divider()
                        .overlay(sectionDividerColor)
                        .padding(.vertical, 2)
                  }
               }
            }
         }

         HStack(spacing: 18) {
            NavigationLink {
               WriteItemView(kind: kind, personID: person.id)
            } label: {
               Text(addTitle)
                  .font(typography.button)
                  .foregroundStyle(kind.color)
                  .lineLimit(2)
            }
            .buttonStyle(.plain)

            if !items.isEmpty {
               NavigationLink {
                  ItemListView(kind: kind, personID: person.id)
               } label: {
                  Text("ViewAllButton")
                     .font(typography.subtext)
                     .foregroundStyle(.secondary)
               }
               .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
         }
         .frame(minHeight: 36)
      }
      .padding(layout.cardPadding)
      .background(sectionBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(kind.color.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
      )
   }

   private var sectionBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : LikehateTheme.surface.opacity(0.78)
   }

   private var sectionDividerColor: Color {
      colorScheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.06)
   }

   private var addTitle: LocalizedStringKey {
      switch (kind, person.isMe) {
      case (.like, _):
         return "AddLikeInlineButton"
      case (.hate, _):
         return "AddHateInlineButton"
      }
   }
}

struct ComparisonSelectionView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var firstPersonID: UUID?
   @State private var secondPersonID: UUID?
   @State private var formMode: PersonFormMode?

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if store.persons.count < 2 {
            ContentUnavailableView {
               Label("CompareEmptyTitle", systemImage: "person.2.slash")
            } description: {
               Text("CompareEmptyMessage")
            } actions: {
               Button {
                  formMode = .add
               } label: {
                  Label("AddPersonButton", systemImage: "plus")
               }
               .buttonStyle(.borderedProminent)
            }
         } else {
            ScrollView {
               VStack(alignment: .leading, spacing: layout.cardSpacing) {
                  VStack(alignment: .leading, spacing: layout.cardSpacing) {
                     VStack(alignment: .leading, spacing: 8) {
                        Text("CompareFirstPersonTitle")
                           .font(typography.subtext)
                           .foregroundStyle(.secondary)

                        personMenu(selection: $firstPersonID, typography: typography)
                     }

                     Divider()
                        .overlay(LikehateTheme.separator)

                     VStack(alignment: .leading, spacing: 8) {
                        Text("CompareSecondPersonTitle")
                           .font(typography.subtext)
                           .foregroundStyle(.secondary)

                        personMenu(selection: $secondPersonID, typography: typography)
                     }
                  }
                  .padding(layout.cardPadding)
                  .background(LikehateTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                  .overlay(
                     RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(LikehateTheme.border, lineWidth: 1)
                  )
                  .shadow(color: LikehateTheme.cardShadow(for: colorScheme), radius: 12, x: 0, y: 4)

                  if let firstPersonID, let secondPersonID, firstPersonID != secondPersonID {
                     NavigationLink {
                        ComparisonResultView(firstPersonID: firstPersonID, secondPersonID: secondPersonID)
                     } label: {
                        Text("CompareButton")
                           .font(typography.button)
                           .frame(maxWidth: .infinity)
                           .frame(minHeight: 56)
                     }
                     .buttonStyle(.borderedProminent)
                     .tint(EntryKind.hate.color)
                  } else {
                     Text("CompareSamePersonMessage")
                        .font(typography.subtext)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight, alignment: .leading)
                  }
               }
               .padding(layout.screenPadding)
            }
            .background(LikehateTheme.background)
         }
      }
      .navigationTitle("CompareTitle")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(item: $formMode) { formMode in
         NavigationStack {
            PersonFormView(mode: formMode)
         }
      }
      .onAppear {
         normalizeSelection()
         Analytics.logEvent("screen_view_compare_selection", parameters: [
            "person_count": store.persons.count,
            "entry_count": store.totalItemCount
         ])
      }
      .onChange(of: store.persons) {
         normalizeSelection()
      }
   }

   private func normalizeSelection() {
      let personIDs = Set(store.persons.map(\.id))
      if firstPersonID == nil || !personIDs.contains(firstPersonID!) {
         firstPersonID = store.mePerson?.id ?? store.persons.first?.id
      }

      if secondPersonID == nil || !personIDs.contains(secondPersonID!) || secondPersonID == firstPersonID {
         secondPersonID = store.persons.first { $0.id != firstPersonID }?.id
      }
   }

   private func personMenu(selection: Binding<UUID?>, typography: AppTypography) -> some View {
      Menu {
         ForEach(store.persons) { person in
            Button {
               selection.wrappedValue = person.id
            } label: {
               Text(verbatim: person.displayName)
            }
         }
      } label: {
         Text(verbatim: selectedPersonName(for: selection.wrappedValue))
            .font(typography.cardTitle)
            .foregroundStyle(selectionTextColor)
            .fontWeight(.bold)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
   }

   private func selectedPersonName(for personID: UUID?) -> String {
      guard let personID, let person = store.person(for: personID) else { return "" }
      return person.displayName
   }

   private var selectionTextColor: Color {
      colorScheme == .dark ? .white.opacity(0.92) : Color(red: 0.24, green: 0.21, blue: 0.29)
   }
}

struct ComparisonResultView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let sections = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID)
            let commonSections = sections.filter { $0.category == .commonLike || $0.category == .commonHate }
            let differenceSections = sections.filter { $0.category != .commonLike && $0.category != .commonHate }
            ScrollView {
               VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                  ComparisonPeopleHeader(firstPerson: firstPerson, secondPerson: secondPerson)

                  Text(verbatim: comparisonSummaryText(sections: sections, secondPerson: secondPerson))
                     .font(typography.body)
                     .foregroundStyle(.primary)
                     .padding(layout.cardPadding)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .background(comparisonSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                     .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                           .stroke(LikehateTheme.border, lineWidth: 1)
                     )

                  ComparisonResultGroup(
                     title: "ComparisonTogetherTitle",
                     sections: commonSections.filter { $0.category == .commonLike },
                     firstPerson: firstPerson,
                     secondPerson: secondPerson,
                     firstPersonID: firstPersonID,
                     secondPersonID: secondPersonID
                  )

                  ComparisonResultGroup(
                     title: "ComparisonAvoidTitle",
                     sections: commonSections.filter { $0.category == .commonHate },
                     firstPerson: firstPerson,
                     secondPerson: secondPerson,
                     firstPersonID: firstPersonID,
                     secondPersonID: secondPersonID
                  )

                  ComparisonResultGroup(
                     title: "ComparisonDifferencesTitle",
                     sections: differenceSections,
                     firstPerson: firstPerson,
                     secondPerson: secondPerson,
                     firstPersonID: firstPersonID,
                     secondPersonID: secondPersonID
                  )
               }
               .padding(layout.screenPadding)
            }
            .onAppear {
               Analytics.logEvent("screen_view_compare_result", parameters: [
                  "first_person_id": firstPersonID.uuidString,
                  "second_person_id": secondPersonID.uuidString,
                  "person_count": store.persons.count
               ])
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle("CompareTitle")
      .navigationBarTitleDisplayMode(.inline)
      .background(LikehateTheme.background)
   }

   private func comparisonSummaryText(sections: [ComparisonSection], secondPerson: Person) -> String {
      let commonLikeCount = sections.first { $0.category == .commonLike }?.titles.count ?? 0
      let commonHateCount = sections.first { $0.category == .commonHate }?.titles.count ?? 0

      if commonLikeCount > 0 {
         return String.localizedStringWithFormat(String(localized: "ComparisonSummaryCommonLikeFormat"), commonLikeCount)
      }

      if commonHateCount > 0 {
         return String.localizedStringWithFormat(String(localized: "ComparisonSummaryCommonHateFormat"), commonHateCount)
      }

      return String(localized: "ComparisonSummaryNoCommonLike")
   }

   private var comparisonSurface: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : LikehateTheme.surface.opacity(0.82)
   }
}

private struct ComparisonPeopleHeader: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(alignment: .center, spacing: 12) {
         HStack(spacing: 8) {
            PersonAvatar(person: firstPerson, size: 38)

            Text(verbatim: firstPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.leading)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .layoutPriority(1)

         Text("ComparisonSeparatorAnd")
            .font(typography.body)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .fixedSize(horizontal: true, vertical: false)

         HStack(spacing: 8) {
            Text(verbatim: secondPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.trailing)

            PersonAvatar(person: secondPerson, size: 38)
         }
         .frame(maxWidth: .infinity, alignment: .trailing)
         .layoutPriority(1)
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, minHeight: layout.rowMinHeight)
      .background(headerBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(LikehateTheme.border, lineWidth: 1)
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: comparisonAccessibilityLabel))
   }

   private var headerBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : LikehateTheme.surface.opacity(0.82)
   }

   private var comparisonAccessibilityLabel: String {
      String.localizedStringWithFormat(
         String(localized: "ComparisonSubtitleFormat"),
         firstPerson.displayName,
         secondPerson.displayName
      )
   }
}

private struct ComparisonResultGroup: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: LocalizedStringKey
   let sections: [ComparisonSection]
   let firstPerson: Person
   let secondPerson: Person
   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      VStack(alignment: .leading, spacing: 12) {
         Text(title)
            .font(typography.cardTitle)
            .foregroundStyle(.primary)
            .padding(.horizontal, 2)

         VStack(spacing: max(12, layout.cardSpacing - 4)) {
            ForEach(sections) { section in
               NavigationLink {
                  ComparisonCategoryDetailView(
                     category: section.category,
                     firstPersonID: firstPersonID,
                     secondPersonID: secondPersonID
                  )
               } label: {
                  ComparisonCard(
                     title: section.category.title(first: firstPerson, second: secondPerson),
                     count: section.titles.count,
                     category: section.category,
                     firstPerson: firstPerson,
                     secondPerson: secondPerson
                  )
               }
               .buttonStyle(.plain)
            }
         }
      }
   }
}

private struct ComparisonCard: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let title: String
   let count: Int
   let category: ComparisonCategory
   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(spacing: 8) {
         Capsule()
            .fill(category.kind.color.opacity(colorScheme == .dark ? 0.78 : 0.64))
            .frame(width: 3, height: 30)

         ComparisonCategoryAvatar(
            category: category,
            firstPerson: firstPerson,
            secondPerson: secondPerson
         )

         Text(verbatim: title)
            .font(typography.body)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

         Spacer(minLength: 8)

         Text(verbatim: String.localizedStringWithFormat(String(localized: "ItemsCountFormat"), count))
            .font(typography.subtext)
            .foregroundStyle(.secondary)
            .frame(minWidth: 48, alignment: .trailing)

         Image(systemName: "chevron.right")
            .font(typography.subtext)
            .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, minHeight: max(66, layout.rowMinHeight), alignment: .leading)
      .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
         RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(category.kind.color.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
      )
      .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
   }

   private var cardBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.05) : LikehateTheme.surface.opacity(0.8)
   }
}

private struct ComparisonCategoryAvatar: View {
   let category: ComparisonCategory
   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      switch category {
      case .commonLike, .commonHate:
         OverlappingComparisonAvatars(firstPerson: firstPerson, secondPerson: secondPerson)
      case .firstOnlyLike, .firstOnlyHate:
         PersonAvatar(person: firstPerson, size: 30)
            .frame(width: 30, alignment: .leading)
            .accessibilityHidden(true)
      case .secondOnlyLike, .secondOnlyHate:
         PersonAvatar(person: secondPerson, size: 30)
            .frame(width: 30, alignment: .leading)
            .accessibilityHidden(true)
      }
   }
}

private struct OverlappingComparisonAvatars: View {
   @Environment(\.colorScheme) private var colorScheme

   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      ZStack(alignment: .leading) {
         PersonAvatar(person: firstPerson, size: 30)

         PersonAvatar(person: secondPerson, size: 30)
            .padding(2)
            .background(overlapBorder, in: Circle())
            .offset(x: 18)
      }
      .frame(width: 48, height: 34, alignment: .leading)
      .padding(4)
      .background(avatarBackground, in: Capsule())
      .accessibilityHidden(true)
   }

   private var avatarBackground: Color {
      colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.7)
   }

   private var overlapBorder: Color {
      colorScheme == .dark ? LikehateTheme.surface : .white
   }
}

struct ComparisonCategoryDetailView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let category: ComparisonCategory
   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let section = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID).first { $0.category == category }
            let titles = section?.titles ?? []

            VStack(alignment: .leading, spacing: 0) {
               Text(verbatim: comparisonSubtitle(firstPerson: firstPerson, secondPerson: secondPerson))
                  .font(typography.body)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, layout.screenPadding)
                  .padding(.top, 14)
                  .padding(.bottom, 6)

               List {
                  if titles.isEmpty {
                     Text(verbatim: emptyMessage(category: category, firstPerson: firstPerson, secondPerson: secondPerson))
                        .font(typography.bodyRegular)
                        .foregroundStyle(.secondary)
                  } else {
                     ForEach(titles, id: \.self) { title in
                        Text(verbatim: title)
                           .font(typography.bodyRegular)
                     }
                  }
               }
            }
            .background(LikehateTheme.background)
            .navigationTitle(category.title(first: firstPerson, second: secondPerson))
            .navigationBarTitleDisplayMode(.inline)
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
   }

   private func emptyMessage(category: ComparisonCategory, firstPerson: Person, secondPerson: Person) -> String {
      switch category {
      case .commonLike:
         return String(localized: "ComparisonEmptyCommonLike")
      case .commonHate:
         return String(localized: "ComparisonEmptyCommonHate")
      case .firstOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptyFirstOnlyLikeFormat"), firstPerson.displayName)
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyLikeFormat"), secondPerson.displayName)
      case .firstOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptyFirstOnlyHateFormat"), firstPerson.displayName)
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyHateFormat"), secondPerson.displayName)
      }
   }

   private func comparisonSubtitle(firstPerson: Person, secondPerson: Person) -> String {
      String.localizedStringWithFormat(
         String(localized: "ComparisonSubtitleFormat"),
         firstPerson.displayName,
         secondPerson.displayName
      )
   }
}
