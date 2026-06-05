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
   @State private var isShowingPremium = false

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
               FAAnalytics.log(.track(.personSelectionAddTapped, parameters: personSelectionAnalyticsParameters))
               showAddPersonOrPremium()
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
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.personSelection, parameters: personSelectionAnalyticsParameters))
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

   private func showAddPersonOrPremium() {
      if store.canAddPerson {
         formMode = .add
      } else {
         FAAnalytics.log(.track(.personSelectionPremiumGateShown, parameters: personSelectionAnalyticsParameters.merging([
            "reason": "person_limit"
         ]) { _, new in new }))
         isShowingPremium = true
      }
   }

   private var personSelectionAnalyticsParameters: [String: Any] {
      [
         "mode": mode == .register ? "register" : "browse",
         "person_count": store.persons.count,
         "entry_count": store.totalItemCount,
         "did_buy_premium": store.didBuyPremium
      ]
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
   var showsShadow = true

   var body: some View {
      PersonAvatarContent(
         image: store.photoImage(for: person),
         profileImage: person.profileImage,
         size: size,
         showsShadow: showsShadow
      )
   }
}

private struct PersonAvatarContent: View {
   let image: UIImage?
   let profileImage: DefaultProfileImage
   let size: CGFloat
   var showsShadow = true

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
         .shadow(color: showsShadow ? Color.black.opacity(0.08) : .clear, radius: showsShadow ? 5 : 0, x: 0, y: showsShadow ? 2 : 0)
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

   var title: String {
      switch self {
      case .add:
         return String(localized: "AddPersonTitle")
      case .edit(let person):
         return String.localizedStringWithFormat(String(localized: "EditPersonTitleFormat"), person.displayName)
      }
   }

   var saveTitle: LocalizedStringKey {
      switch self {
      case .add: return "AddPersonSaveButton"
      case .edit: return "SavePersonChangesButton"
      }
   }

   var allowsNameEditing: Bool {
      true
   }
}

struct PersonFormView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dismiss) private var dismiss
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var name: String
   @State private var iconSelection: PersonIconSelectionState
   @State private var selectedPhotoItem: PhotosPickerItem?
   @State private var selectedPhotoData: Data?
   @State private var selectedPhotoPreview: UIImage?
   @State private var cropSourceImage: PersonPhotoCropSource?
   @State private var isLoadingPhoto = false
   @State private var isShowingDeleteConfirmation = false
   @State private var isShowingPremium = false
   @State private var didApplyInitialAddProfileImage = false
   @FocusState private var isNameFocused: Bool

   let mode: PersonFormMode
   var onAdd: ((Person) -> Void)?

   init(mode: PersonFormMode, onAdd: ((Person) -> Void)? = nil) {
      self.mode = mode
      self.onAdd = onAdd
      switch mode {
      case .add:
         _name = State(initialValue: "")
         _iconSelection = State(initialValue: PersonIconSelectionState(selectedProfileImage: .defaultProfileImage, hasExistingPhoto: false))
      case .edit(let person):
         _name = State(initialValue: person.displayName)
         _iconSelection = State(initialValue: PersonIconSelectionState(selectedProfileImage: person.profileImage, hasExistingPhoto: person.photoFileName != nil))
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
                  profileImage: iconSelection.selectedProfileImage,
                  size: 84
               )

               PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                  Label(currentPhotoButtonTitle, systemImage: "photo")
                     .font(typography.button)
                     .foregroundStyle(LikehateTheme.likeAccent)
               }
               .disabled(isLoadingPhoto)
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.personFormPhotoTapped, parameters: formAnalyticsParameters))
                  iconSelection.beginPhotoSelection()
               })

               if isLoadingPhoto {
                  ProgressView("LoadingPersonPhoto")
                     .font(typography.subtext)
               }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
         } footer: {
            if case .edit = mode {
               Text("EditPersonHelpText")
            }
         }

         if allowsNameEditing {
            Section {
               TextField("PersonNamePlaceholder", text: $name)
                  .font(typography.bodyRegular)
                  .textInputAutocapitalization(.words)
                  .autocorrectionDisabled()
                  .focused($isNameFocused)
                  .submitLabel(.done)
                  .onSubmit {
                     applyNameSubmitAction(PersonNameSubmitAction.done.action())
                  }
                  .onChange(of: name) { _, newValue in
                     if newValue.count > PersonNameRules.maxLength {
                        name = PersonNameRules.limited(newValue)
                     }
                  }
            } footer: {
               if case .add = mode {
                  Text("AddPersonHelpText")
               }
            }
         }

         Section("ProfileImageSectionTitle") {
            DefaultProfileImagePicker(selectedProfileImage: iconSelection.selectedProfileImage) { profileImage in
               selectProfileImage(profileImage)
            }
         }

         if case .edit(let person) = mode, !person.isMe {
            Section {
               Button(role: .destructive) {
                  FAAnalytics.log(.track(.personFormDeleteTapped, parameters: formAnalyticsParameters.merging([
                     "person_id": person.id.uuidString
                  ]) { _, new in new }))
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
            Button {
               dismiss()
            } label: {
               Image(systemName: "xmark")
                  .font(typography.body)
            }
            .accessibilityLabel(Text("cancel"))
         }

         ToolbarItem(placement: .confirmationAction) {
            Button(mode.saveTitle) {
               FAAnalytics.log(.track(.personFormSaveTapped, parameters: formAnalyticsParameters.merging([
                  "name_length": trimmedName.count,
                  "has_selected_photo": selectedPhotoData != nil
               ]) { _, new in new }))
               save()
            }
            .disabled(isLoadingPhoto || (allowsNameEditing && trimmedName.isEmpty))
         }
      }
      .confirmationDialog(
         String(localized: "DeletePersonConfirmationTitle"),
         isPresented: $isShowingDeleteConfirmation,
         titleVisibility: .visible
      ) {
         Button(String(localized: "DeletePersonConfirmButton"), role: .destructive) {
            if case .edit(let person) = mode {
               FAAnalytics.log(.track(.personFormDeleteConfirmed, parameters: formAnalyticsParameters.merging([
                  "person_id": person.id.uuidString,
                  "is_me": person.isMe
               ]) { _, new in new }))
               store.deletePerson(person.id)
            }
            dismiss()
         }
         Button(String(localized: "cancel"), role: .cancel) {
            FAAnalytics.log(.track(.personFormDeleteCancelled, parameters: formAnalyticsParameters))
         }
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
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .onAppear {
         FAAnalytics.log(.screenView(.personForm, parameters: formAnalyticsParameters))
         if case .add = mode {
            applyInitialAddProfileImageIfNeeded()
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

   private var allowsNameEditing: Bool {
      mode.allowsNameEditing
   }

   private var previewImage: UIImage? {
      if let selectedPhotoPreview {
         return selectedPhotoPreview
      }

      guard !iconSelection.removesExistingPhoto else { return nil }
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

   private func save() {
      guard !allowsNameEditing || !trimmedName.isEmpty else { return }

      switch mode {
      case .add:
         guard store.canAddPerson else {
            FAAnalytics.log(.track(.personFormPremiumGateShown, parameters: formAnalyticsParameters.merging([
               "reason": "person_limit"
            ]) { _, new in new }))
            isShowingPremium = true
            return
         }
         if let person = store.addPerson(named: name, profileImage: iconSelection.selectedProfileImage, photoData: selectedPhotoData) {
            onAdd?(person)
         } else {
            FAAnalytics.log(.track(.personFormPremiumGateShown, parameters: formAnalyticsParameters.merging([
               "reason": "person_limit_or_invalid"
            ]) { _, new in new }))
            isShowingPremium = true
            return
         }
      case .edit(let person):
         store.updatePerson(
            person.id,
            name: allowsNameEditing ? name : person.name,
            profileImage: iconSelection.selectedProfileImage,
            photoData: selectedPhotoData,
            removesPhoto: iconSelection.removesExistingPhoto
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
            FAAnalytics.log(.track(.personFormPhotoLoadFailed, parameters: formAnalyticsParameters.merging([
               "reason": "missing_image_data"
            ]) { _, new in new }))
            return
         }

         FAAnalytics.log(.track(.personFormPhotoLoaded, parameters: formAnalyticsParameters))
         cropSourceImage = PersonPhotoCropSource(image: image)
      } catch {
         selectedPhotoData = nil
         selectedPhotoPreview = nil
         FAAnalytics.log(.track(.personFormPhotoLoadFailed, parameters: formAnalyticsParameters.merging([
            "error_description": error.localizedDescription
         ]) { _, new in new }))
      }
   }

   private func applyNameSubmitAction(_ action: PersonNameSubmitAction.Action) {
      switch action {
      case .dismissKeyboard:
         isNameFocused = false
      }
   }

   private func applyInitialAddProfileImageIfNeeded() {
      guard didApplyInitialAddProfileImage == false else { return }
      iconSelection = PersonIconSelectionState(selectedProfileImage: store.defaultProfileImageForNewPerson(), hasExistingPhoto: false)
      didApplyInitialAddProfileImage = true
   }

   private func finishCropping(image: UIImage) {
      let imageData = image.pngData() ?? image.jpegData(compressionQuality: 0.92)
      guard
         let imageData,
         let thumbnailData = LikeHateStore.thumbnailPhotoData(from: imageData),
         let thumbnail = UIImage(data: thumbnailData)
      else {
         cropSourceImage = nil
         FAAnalytics.log(.track(.personFormPhotoCropFailed, parameters: formAnalyticsParameters))
         return
      }

      selectedPhotoData = thumbnailData
      selectedPhotoPreview = thumbnail
      iconSelection.didSelectPhoto()
      cropSourceImage = nil
      FAAnalytics.log(.track(.personFormPhotoCropped, parameters: formAnalyticsParameters))
   }

   private func selectProfileImage(_ profileImage: DefaultProfileImage) {
      FAAnalytics.log(.track(.personFormPresetSelected, parameters: formAnalyticsParameters.merging([
         "profile_image": profileImage.rawValue
      ]) { _, new in new }))
      iconSelection.selectProfileImage(profileImage)
      selectedPhotoItem = nil
      selectedPhotoData = nil
      selectedPhotoPreview = nil
      cropSourceImage = nil
   }

   private var formAnalyticsParameters: [String: Any] {
      var parameters: [String: Any] = [
         "mode": mode.id,
         "person_count": store.persons.count,
         "entry_count": store.totalItemCount,
         "selected_profile_image": iconSelection.selectedProfileImage.rawValue,
         "has_selected_photo": selectedPhotoData != nil,
         "removes_existing_photo": iconSelection.removesExistingPhoto
      ]

      if case .edit(let person) = mode {
         parameters["person_id"] = person.id.uuidString
         parameters["is_me"] = person.isMe
         parameters["has_existing_photo"] = person.photoFileName != nil
      }

      return parameters
   }
}

enum PersonNameSubmitAction {
   enum Action: Equatable {
      case dismissKeyboard
   }

   case done

   func action() -> Action {
      switch self {
      case .done:
         return .dismissKeyboard
      }
   }
}

struct PersonIconSelectionState: Equatable {
   var selectedProfileImage: DefaultProfileImage
   private(set) var removesExistingPhoto: Bool

   private let hasExistingPhoto: Bool

   init(selectedProfileImage: DefaultProfileImage, hasExistingPhoto: Bool) {
      self.selectedProfileImage = selectedProfileImage
      self.hasExistingPhoto = hasExistingPhoto
      self.removesExistingPhoto = false
   }

   mutating func beginPhotoSelection() {}

   mutating func didSelectPhoto() {
      removesExistingPhoto = false
   }

   mutating func selectProfileImage(_ profileImage: DefaultProfileImage) {
      selectedProfileImage = profileImage
      removesExistingPhoto = hasExistingPhoto
   }
}

private struct DefaultProfileImagePicker: View {
   let selectedProfileImage: DefaultProfileImage
   let onSelect: (DefaultProfileImage) -> Void

   private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

   var body: some View {
      LazyVGrid(columns: columns, spacing: 12) {
         ForEach(DefaultProfileImage.allCases) { profileImage in
            Button {
               onSelect(profileImage)
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
                  HStack(spacing: 16) {
                     PersonAvatar(person: person, size: 83)

                     Text(verbatim: person.displayName)
                        .font(typography.screenTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                  }
                  .padding(.top, 8)

                  PersonEntryPreviewSection(person: person, kind: .like)
                  PersonEntryPreviewSection(person: person, kind: .hate)

                  comparisonLink(for: person)
                     .padding(.top, -(layout.sectionSpacing / 3))
               }
               .padding(.horizontal, layout.screenPadding)
               .padding(.vertical, layout.cardSpacing)
            }
            .background(LikehateTheme.background)
            .navigationTitle(person.displayName)
            .toolbar {
               ToolbarItem(placement: .topBarTrailing) {
                  Button {
                     FAAnalytics.log(.track(.personDetailEditTapped, parameters: personDetailAnalyticsParameters(person: person)))
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
         var parameters: [String: Any] = [
            "person_id": personID.uuidString,
            "person_count": store.persons.count,
            "entry_count": store.totalItemCount
         ]
         if let person = store.person(for: personID) {
            parameters["is_me"] = person.isMe
         }
         FAAnalytics.log(.screenView(.personDetail, parameters: parameters))
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
            .padding(.top, 3)
            .frame(maxWidth: .infinity, minHeight: max(56, layout.rowMinHeight), alignment: .leading)
            .contentShape(Rectangle())
         }
         .buttonStyle(.plain)
         .simultaneousGesture(TapGesture().onEnded {
            FAAnalytics.log(.track(.personDetailCompareTapped, parameters: personDetailAnalyticsParameters(person: person).merging([
               "target": "direct_compare"
            ]) { _, new in new }))
         })
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
            .padding(.top, 3)
            .frame(maxWidth: .infinity, minHeight: max(56, layout.rowMinHeight), alignment: .leading)
            .contentShape(Rectangle())
         }
         .buttonStyle(.plain)
         .simultaneousGesture(TapGesture().onEnded {
            FAAnalytics.log(.track(.personDetailCompareTapped, parameters: personDetailAnalyticsParameters(person: person).merging([
               "target": "compare_selection"
            ]) { _, new in new }))
         })
      }
   }

   private func personDetailAnalyticsParameters(person: Person) -> [String: Any] {
      [
         "person_id": person.id.uuidString,
         "is_me": person.isMe,
         "person_count": store.persons.count,
         "entry_count": store.totalItemCount
      ]
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
      let previewItems = EntryPreviewItems.items(from: items)
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
            .simultaneousGesture(TapGesture().onEnded {
               FAAnalytics.log(.track(.personDetailAddEntryTapped, parameters: sectionAnalyticsParameters(itemCount: items.count)))
            })

            if !items.isEmpty {
               NavigationLink {
                  ItemListView(kind: kind, personID: person.id)
               } label: {
                  Text("ViewAllButton")
                     .font(typography.subtext)
                     .foregroundStyle(.secondary)
               }
               .buttonStyle(.plain)
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.personDetailViewAllTapped, parameters: sectionAnalyticsParameters(itemCount: items.count)))
               })
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

   private func sectionAnalyticsParameters(itemCount: Int) -> [String: Any] {
      [
         "person_id": person.id.uuidString,
         "is_me": person.isMe,
         "kind": kind.rawValue,
         "item_count": itemCount,
         "person_count": store.persons.count
      ]
   }
}

struct ComparisonSelectionView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize
   @State private var firstPersonID: UUID?
   @State private var secondPersonID: UUID?
   @State private var formMode: PersonFormMode?
   @State private var isShowingPremium = false

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      Group {
         if store.persons.count < 2 {
            comparisonEmptyState(typography: typography, layout: layout)
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
                     .simultaneousGesture(TapGesture().onEnded {
                        FAAnalytics.log(.track(.compareSelectionSubmitTapped, parameters: comparisonSelectionAnalyticsParameters.merging([
                           "first_person_id": firstPersonID.uuidString,
                           "second_person_id": secondPersonID.uuidString
                        ]) { _, new in new }))
                     })
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
      .sheet(isPresented: $isShowingPremium) {
         NavigationStack {
            PremiumView()
         }
      }
      .onAppear {
         normalizeSelection()
         FAAnalytics.log(.screenView(.compareSelection, parameters: comparisonSelectionAnalyticsParameters))
      }
      .onChange(of: store.persons) {
         normalizeSelection()
      }
   }

   private func comparisonEmptyState(typography: AppTypography, layout: AppLayoutMetrics) -> some View {
      ZStack {
         LikehateTheme.background
            .ignoresSafeArea()

         GeometryReader { proxy in
            ScrollView {
               VStack(spacing: layout.cardSpacing) {
                  EmptyMemoStateView(
                     systemImage: "person.2",
                     accent: LikehateTheme.likeAccent,
                     title: String(localized: "CompareEmptyTitle"),
                     message: String(localized: "CompareEmptyMessage")
                  )

                  Button {
                     FAAnalytics.log(.track(.compareSelectionAddPersonTapped, parameters: comparisonSelectionAnalyticsParameters))
                     showAddPersonOrPremium()
                  } label: {
                     Label("AddPersonButton", systemImage: "plus")
                        .font(typography.button)
                        .foregroundStyle(LikehateTheme.likeAccent)
                        .frame(minHeight: 48)
                  }
                  .buttonStyle(.plain)
               }
               .frame(maxWidth: .infinity)
               .frame(minHeight: proxy.size.height, alignment: .center)
               .padding(.horizontal, layout.screenPadding)
               .padding(.vertical, layout.sectionSpacing)
               .offset(y: -24)
            }
         }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
               FAAnalytics.log(.track(.compareSelectionPersonChanged, parameters: comparisonSelectionAnalyticsParameters.merging([
                  "selected_person_id": person.id.uuidString,
                  "is_me": person.isMe
               ]) { _, new in new }))
            } label: {
               Text(verbatim: person.displayName)
            }
         }
      } label: {
         if let selectedPerson = selectedPerson(for: selection.wrappedValue) {
            HStack(spacing: 12) {
               PersonAvatar(person: selectedPerson, size: 44, showsShadow: false)

               Text(verbatim: selectedPerson.displayName)
                  .font(typography.cardTitle)
                  .foregroundStyle(selectionTextColor)
                  .fontWeight(.bold)
                  .lineLimit(1)

               Spacer(minLength: 8)

               Image(systemName: "chevron.down")
                  .font(typography.subtext)
                  .fontWeight(.bold)
                  .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
         }
      }
      .buttonStyle(.plain)
   }

   private func selectedPerson(for personID: UUID?) -> Person? {
      guard let personID else { return nil }
      return store.person(for: personID)
   }

   private func showAddPersonOrPremium() {
      if store.canAddPerson {
         formMode = .add
      } else {
         FAAnalytics.log(.track(.compareSelectionPremiumGateShown, parameters: comparisonSelectionAnalyticsParameters.merging([
            "reason": "person_limit"
         ]) { _, new in new }))
         isShowingPremium = true
      }
   }

   private var selectionTextColor: Color {
      colorScheme == .dark ? .white.opacity(0.92) : Color(red: 0.24, green: 0.21, blue: 0.29)
   }

   private var comparisonSelectionAnalyticsParameters: [String: Any] {
      [
         "person_count": store.persons.count,
         "entry_count": store.totalItemCount,
         "did_buy_premium": store.didBuyPremium
      ]
   }
}

struct ComparisonResultView: View {
   @EnvironmentObject private var store: LikeHateStore

   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let sections = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID)
            ScrollView {
               VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                  ComparisonPeopleHeader(firstPerson: firstPerson, secondPerson: secondPerson)

                  ForEach(ComparisonResultSectionGroup.ordered) { group in
                     ComparisonResultGroup(
                        title: LocalizedStringKey(group.titleKey),
                        sections: group.sections(from: sections),
                        firstPerson: firstPerson,
                        secondPerson: secondPerson,
                        firstPersonID: firstPersonID,
                        secondPersonID: secondPersonID
                     )
                  }
               }
               .padding(layout.screenPadding)
            }
            .onAppear {
               FAAnalytics.log(.screenView(.compareResult, parameters: [
                  "first_person_id": firstPersonID.uuidString,
                  "second_person_id": secondPersonID.uuidString,
                  "person_count": store.persons.count
               ]))
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
      .navigationTitle("CompareTitle")
      .navigationBarTitleDisplayMode(.inline)
      .background(LikehateTheme.background)
   }
}

private struct ComparisonPeopleHeader: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let firstPerson: Person
   let secondPerson: Person

   var body: some View {
      let typography = store.typography(for: dynamicTypeSize)
      let layout = store.layoutMetrics

      HStack(alignment: .center, spacing: 16) {
         DiagonalOverlappingPersonAvatars(
            firstPerson: firstPerson,
            secondPerson: secondPerson,
            size: ComparisonAvatarMetrics.headerSize,
            horizontalOffset: ComparisonAvatarMetrics.headerOverlapOffset,
            verticalOffset: ComparisonAvatarMetrics.headerDiagonalOffset
         )

         HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(verbatim: firstPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.leading)

            Text("ComparisonSeparatorAnd")
               .font(typography.body)
               .foregroundStyle(.secondary)
               .fixedSize(horizontal: true, vertical: false)

            Text(verbatim: secondPerson.displayName)
               .font(typography.cardTitle)
               .foregroundStyle(.primary)
               .lineLimit(2)
               .multilineTextAlignment(.leading)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .layoutPriority(1)
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, minHeight: max(68, layout.rowMinHeight + 8), alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: comparisonAccessibilityLabel))
   }

   private var comparisonAccessibilityLabel: String {
      String.localizedStringWithFormat(
         String(localized: "ComparisonSubtitleFormat"),
         firstPerson.displayName,
         secondPerson.displayName
      )
   }
}

private enum ComparisonAvatarMetrics {
   static let headerSize: CGFloat = 53
   static let headerOverlapOffset: CGFloat = 26
   static let headerDiagonalOffset: CGFloat = 10
   static let categorySize: CGFloat = 42
   static let categoryOverlapOffset: CGFloat = 25
   static let categoryDiagonalOffset: CGFloat = 8
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
               .simultaneousGesture(TapGesture().onEnded {
                  FAAnalytics.log(.track(.comparisonCategoryTapped, parameters: [
                     "category": section.category.rawValue,
                     "kind": section.category.kind.rawValue,
                     "item_count": section.titles.count,
                     "first_person_id": firstPersonID.uuidString,
                     "second_person_id": secondPersonID.uuidString
                  ]))
               })
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

      HStack(spacing: 12) {
         Capsule()
            .fill(category.kind.color.opacity(colorScheme == .dark ? 0.78 : 0.64))
            .frame(width: 3, height: ComparisonAvatarMetrics.categorySize)

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
      }
      .padding(.horizontal, layout.cardPadding)
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity, minHeight: max(82, layout.rowMinHeight + 18), alignment: .leading)
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
         DiagonalOverlappingPersonAvatars(
            firstPerson: firstPerson,
            secondPerson: secondPerson,
            size: ComparisonAvatarMetrics.categorySize,
            horizontalOffset: ComparisonAvatarMetrics.categoryOverlapOffset,
            verticalOffset: ComparisonAvatarMetrics.categoryDiagonalOffset,
            showsBackground: true
         )
      case .firstOnlyLike, .firstOnlyHate:
         PersonAvatar(person: firstPerson, size: ComparisonAvatarMetrics.categorySize)
            .frame(width: ComparisonAvatarMetrics.categorySize, alignment: .leading)
            .accessibilityHidden(true)
      case .secondOnlyLike, .secondOnlyHate:
         PersonAvatar(person: secondPerson, size: ComparisonAvatarMetrics.categorySize)
            .frame(width: ComparisonAvatarMetrics.categorySize, alignment: .leading)
            .accessibilityHidden(true)
      }
   }
}

struct ComparisonCategoryDetailView: View {
   @EnvironmentObject private var store: LikeHateStore
   @Environment(\.dynamicTypeSize) private var dynamicTypeSize

   let category: ComparisonCategory
   let firstPersonID: UUID
   let secondPersonID: UUID

   var body: some View {
      let layout = store.layoutMetrics

      Group {
         if let firstPerson = store.person(for: firstPersonID), let secondPerson = store.person(for: secondPersonID) {
            let section = store.comparisonSections(firstPersonID: firstPersonID, secondPersonID: secondPersonID).first { $0.category == category }
            let titles = section?.titles ?? []
            let showsBanner = AdDisplayPolicy(adsRemoved: store.appSettings.adsRemoved, isPremium: store.appSettings.isPremium).showsListAd(hasItems: !titles.isEmpty)

            ScrollView {
               VStack(alignment: .leading, spacing: layout.cardSpacing + 8) {
                  PersonPairHeaderView(firstPerson: firstPerson, secondPerson: secondPerson, avatarSize: ComparisonAvatarMetrics.categorySize)
                     .padding(.top, 24)

                  if titles.isEmpty {
                     EmptyMemoStateView(
                        systemImage: emptyStateIcon,
                        accent: category.kind.color,
                        title: emptyTitle(category: category, firstPerson: firstPerson, secondPerson: secondPerson),
                        message: emptyMessage(category: category, firstPerson: firstPerson, secondPerson: secondPerson)
                     )
                     .padding(.top, 44)
                  } else {
                     VStack(spacing: 0) {
                        LikeDislikeListCard(titles: titles, accent: category.kind.color)

                        if showsBanner {
                           ConditionalListAdBanner(
                              placement: .comparisonCategoryDetail,
                              hasItems: !titles.isEmpty,
                              topPadding: max(24, layout.cardSpacing),
                              bottomPadding: 20
                           )
                           .frame(maxWidth: .infinity, alignment: .center)
                           .onAppear {
                              FAAnalytics.log(.track(.comparisonCategoryAdVisible, parameters: categoryDetailAnalyticsParameters(
                                 firstPerson: firstPerson,
                                 secondPerson: secondPerson,
                                 itemCount: titles.count
                              )))
                           }
                        }
                     }
                  }
               }
               .padding(.horizontal, layout.screenPadding)
               .padding(.bottom, layout.sectionSpacing)
            }
            .background(LikehateTheme.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle(category.title(first: firstPerson, second: secondPerson))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
               FAAnalytics.log(.screenView(.comparisonCategoryDetail, parameters: categoryDetailAnalyticsParameters(
                  firstPerson: firstPerson,
                  secondPerson: secondPerson,
                  itemCount: titles.count
               )))
            }
         } else {
            ContentUnavailableView("PersonNotFoundTitle", systemImage: "person.crop.circle.badge.questionmark")
         }
      }
   }

   private var emptyStateIcon: String {
      switch category.kind {
      case .like: return "heart"
      case .hate: return "moon"
      }
   }

   private func emptyTitle(category: ComparisonCategory, firstPerson: Person, secondPerson: Person) -> String {
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

   private func emptyMessage(category: ComparisonCategory, firstPerson: Person, secondPerson: Person) -> String {
      switch category {
      case .commonLike:
         return String(localized: "ComparisonEmptyCommonLikeMessage")
      case .commonHate:
         return String(localized: "ComparisonEmptyCommonHateMessage")
      case .firstOnlyLike:
         return String(localized: "ComparisonEmptyFirstOnlyLikeMessage")
      case .secondOnlyLike:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyLikeMessageFormat"), secondPerson.displayName)
      case .firstOnlyHate:
         return String(localized: "ComparisonEmptyFirstOnlyHateMessage")
      case .secondOnlyHate:
         return String.localizedStringWithFormat(String(localized: "ComparisonEmptySecondOnlyHateMessageFormat"), secondPerson.displayName)
      }
   }

   private func categoryDetailAnalyticsParameters(firstPerson: Person, secondPerson: Person, itemCount: Int) -> [String: Any] {
      [
         "category": category.rawValue,
         "kind": category.kind.rawValue,
         "item_count": itemCount,
         "is_empty": itemCount == 0,
         "first_person_id": firstPerson.id.uuidString,
         "second_person_id": secondPerson.id.uuidString,
         "first_is_me": firstPerson.isMe,
         "second_is_me": secondPerson.isMe,
         "person_count": store.persons.count
      ]
   }
}
