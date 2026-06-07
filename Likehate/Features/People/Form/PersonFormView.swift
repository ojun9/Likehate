import PhotosUI
import SwiftUI
import UIKit

/// 人物の呼び方、写真、プリセット画像を追加・編集するフォーム画面。
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
   @State private var profileImageSource: FAProfileImageSource
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
         _profileImageSource = State(initialValue: .randomPreset)
      case .edit(let person):
         _name = State(initialValue: person.displayName)
         _iconSelection = State(initialValue: PersonIconSelectionState(selectedProfileImage: person.profileImage, hasExistingPhoto: person.photoFileName != nil))
         _profileImageSource = State(initialValue: person.photoFileName == nil ? .existingPreset : .existingPhoto)
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
                  PhotoPickerButtonLabel(
                     title: currentPhotoButtonTitle,
                     typography: typography
                  )
               }
               .buttonStyle(.plain)
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
                     .personID: person.id.uuidString
                  ])))
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
               FAAnalytics.log(.track(.personFormSaveTapped, parameters: formSaveAnalyticsParameters))
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
                  .personID: person.id.uuidString,
                  .isMe: person.isMe
               ])))
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
               .reason: "person_limit"
            ])))
            isShowingPremium = true
            return
         }
         if let person = store.addPerson(
            named: name,
            profileImage: iconSelection.selectedProfileImage,
            profileImageSource: profileImageSource,
            photoData: selectedPhotoData
         ) {
            onAdd?(person)
         } else {
            FAAnalytics.log(.track(.personFormPremiumGateShown, parameters: formAnalyticsParameters.merging([
               .reason: "person_limit_or_invalid"
            ])))
            isShowingPremium = true
            return
         }
      case .edit(let person):
         store.updatePerson(
            person.id,
            name: allowsNameEditing ? name : person.name,
            profileImage: iconSelection.selectedProfileImage,
            profileImageSource: profileImageSource,
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
               .reason: "missing_image_data"
            ])))
            return
         }

         FAAnalytics.log(.track(.personFormPhotoLoaded, parameters: formAnalyticsParameters))
         cropSourceImage = PersonPhotoCropSource(image: image)
      } catch {
         selectedPhotoData = nil
         selectedPhotoPreview = nil
         FAAnalytics.log(.track(.personFormPhotoLoadFailed, parameters: formAnalyticsParameters.merging([
            .errorDescription: error.localizedDescription
         ])))
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
      profileImageSource = .selectedPhoto
      cropSourceImage = nil
      FAAnalytics.log(.track(.personFormPhotoCropped, parameters: formAnalyticsParameters))
   }

   private func selectProfileImage(_ profileImage: DefaultProfileImage) {
      let selectedSource = FAProfileImageSource.selectedPreset
      FAAnalytics.log(.track(.personFormPresetSelected, parameters: formAnalyticsParameters.merging([
         .profileImage: profileImage.rawValue,
         .profileImageSource: selectedSource.rawValue
      ])))
      profileImageSource = selectedSource
      iconSelection.selectProfileImage(profileImage)
      selectedPhotoItem = nil
      selectedPhotoData = nil
      selectedPhotoPreview = nil
      cropSourceImage = nil
   }

   private var formAnalyticsParameters: FAParameters {
      var parameters: FAParameters = [
         .mode: mode.id,
         .personCount: store.persons.count,
         .entryCount: store.totalItemCount,
         .selectedProfileImage: iconSelection.selectedProfileImage.rawValue,
         .profileImageSource: profileImageSource.rawValue,
         .hasSelectedPhoto: selectedPhotoData != nil,
         .removesExistingPhoto: iconSelection.removesExistingPhoto
      ]

      if case .edit(let person) = mode {
         parameters[.personID] = person.id.uuidString
         parameters[.isMe] = person.isMe
         parameters[.hasExistingPhoto] = person.photoFileName != nil
      }

      return parameters
   }

   private var formSaveAnalyticsParameters: FAParameters {
      var parameters = formAnalyticsParameters.merging([
         .nameLength: trimmedName.count,
         .hasSelectedPhoto: selectedPhotoData != nil
      ])

      if let personName = FAPersonNameParameter.value(from: name) {
         parameters[.personName] = personName
      }

      return parameters
   }
}
