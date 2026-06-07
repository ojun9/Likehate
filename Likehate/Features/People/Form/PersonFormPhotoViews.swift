import SwiftUI

struct PhotoPickerButtonLabel: View {
   let title: String
   let typography: AppTypography

   var body: some View {
      Label(title, systemImage: "photo")
         .font(typography.button)
         .foregroundStyle(LikehateTheme.likeAccent)
         .lineLimit(1)
         .minimumScaleFactor(0.85)
         .padding(.horizontal, 18)
         .frame(maxWidth: .infinity, minHeight: 48)
         .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
               .fill(LikehateTheme.likeAccent.opacity(0.12))
         }
         .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
               .stroke(LikehateTheme.likeAccent.opacity(0.22), lineWidth: 1)
         }
         .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
   }
}

struct DefaultProfileImagePicker: View {
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
