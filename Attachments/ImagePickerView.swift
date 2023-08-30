//
//  ImagePickerView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 30/08/23.
//

import SwiftUI
import AVFoundation
import MobileCoreServices
import UniformTypeIdentifiers

struct ImagePickerView: UIViewControllerRepresentable {
  
  @Environment(\.dismiss) private var dismiss
  
  private var sourceType: AttachmentViewModel.SourceType
  @Binding var selectedImage: UIImage?
  @Binding var selectedURL: URL?
  
  init(_ sourceType: AttachmentViewModel.SourceType = .library,
       selectedImage: Binding<UIImage?> = .constant(.none),
       selectedURL: Binding<URL?> = .constant(.none)) {
    _selectedImage = selectedImage
    _selectedURL = selectedURL
    self.sourceType = sourceType
  }
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.allowsEditing = false
    checkSourceType(for: picker)
    picker.delegate = context.coordinator
    return picker
  }
  
  private func checkSourceType(for picker: UIImagePickerController) {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      if sourceType == .takePhoto {
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
      } else if sourceType == .takeVideo {
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 60
      }
    } else {
      picker.sourceType = .photoLibrary
    }
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var parent: ImagePickerView
    
    init(_ parent: ImagePickerView) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      guard let mediaType = info[.mediaType] as? String else { return }
      
      if mediaType == UTType.movie.identifier, let url = info[.mediaURL] as? URL {
        parent.selectedURL = url
      } else if mediaType == UTType.image.identifier, let image = info[.originalImage] as? UIImage {
        parent.selectedImage = image
      }
      parent.dismiss()
    }
  }
}
