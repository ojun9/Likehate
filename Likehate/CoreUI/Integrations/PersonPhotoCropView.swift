import CropViewController
import SwiftUI
import UIKit

/// 写真クロップ画面へ渡す元画像。
struct PersonPhotoCropSource: Identifiable {
   let image: UIImage
   let id = UUID()
}

/// CropViewControllerをSwiftUIのsheetから扱うためのラッパー。
struct PersonPhotoCropView: UIViewControllerRepresentable {
   let sourceImage: UIImage
   let onCrop: (UIImage) -> Void
   let onCancel: () -> Void

   func makeCoordinator() -> Coordinator {
      Coordinator(onCrop: onCrop, onCancel: onCancel)
   }

   func makeUIViewController(context: Context) -> CropViewController {
      let controller = CropViewController(croppingStyle: .circular, image: sourceImage)
      controller.aspectRatioPreset = CGSize(width: 1, height: 1)
      controller.aspectRatioPickerButtonHidden = true
      controller.resetAspectRatioEnabled = false
      controller.rotateButtonsHidden = false
      controller.cancelButtonTitle = String(localized: "cancel")
      controller.doneButtonTitle = String(localized: "SavePersonButton")
      controller.cropView.cropBoxResizeEnabled = false
      controller.delegate = context.coordinator
      return controller
   }

   func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}

   /// CropViewControllerの完了・キャンセルをSwiftUI側のクロージャへ橋渡しする。
   final class Coordinator: NSObject, @MainActor CropViewControllerDelegate {
      private let onCrop: (UIImage) -> Void
      private let onCancel: () -> Void

      init(onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
         self.onCrop = onCrop
         self.onCancel = onCancel
      }

      @MainActor
      func cropViewController(
         _ cropViewController: CropViewController,
         didFinishCancelled cancelled: Bool
      ) {
         onCancel()
      }

      @MainActor
      func cropViewController(
         _ cropViewController: CropViewController,
         didCropToCircularImage image: UIImage,
         withRect cropRect: CGRect,
         angle: Int
      ) {
         onCrop(image)
      }
   }
}
