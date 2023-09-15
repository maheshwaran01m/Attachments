//
//  AttachmentViewModel.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import SwiftUI
import PhotosUI
import MobileCoreServices
import UniformTypeIdentifiers

class AttachmentViewModel: ObservableObject {
  
  @Published var showAttachmentDialog = false
  @Published var photoPicker: PhotosPickerItem? {
    didSet {
      setPhotosPickerItem(for: photoPicker)
    }
  }
  @Published var selectedImage: UIImage? {
    didSet {
      if let uiImage = selectedImage,
         let attachment = self.attachmentManager.saveImage(uiImage, folderName: self.folderName) {
        DispatchQueue.main.async {
          self.attachments.append(attachment)
        }
      }
    }
  }
  @Published var selectedVideo: URL? {
    didSet {
      if let url = selectedVideo,
         let attachment = self.attachmentManager.saveFile(
          url, fileType: url.pathExtension, folderName: self.folderName) {
        DispatchQueue.main.async {
          self.attachments.append(attachment)
        }
      }
    }
  }
  
  @Published var showCamera = false
  @Published var showPhoto = false
  @Published var showFiles = false
  @Published var showAudio = false
  
  @Published var showPhotoEditor = false
  
  @Published var sourceType: SourceType = .library
  @Published var showCameraAlert = false
  
  @Published var attachments: [AttachmentItem] = []
  
  @Published var quickLookURL: URL?
  var attachmentURLs: [URL] {
    attachments.map { URL(filePath: $0.localFilePath) }
  }
  
  @Published var quickLookEdit = false
  @Published var selectedQuickLookItem: QuickLookItem? {
    didSet {
      if let selectedQuickLookItem {
        self.addAttachmentItem(for: selectedQuickLookItem.fileName)
      }
    }
  }
  
  private (set) var selectedAttachmentItem: AttachmentItem?
  private let fileManager = FileManager.default
  private let attachmentManager = AttachmentManager()
  private let folderName: String
  
  init(folderName: String = "Files") {
    self.folderName = folderName
  }
  
  var allowedFileType: [UTType] {
    [.image, .video, .movie, .pdf, .text, .plainText, .spreadsheet,
     .presentation, .mpeg4Movie, .mpeg4Audio,  .init(filenameExtension: "doc") ?? .pdf]
  }
  
  var allowedImageType: PHPickerFilter {
    .any(of: [.images, .screenshots, .depthEffectPhotos])
  }
  
  var allowedVideoType: PHPickerFilter {
    .any(of: [.videos, .screenRecordings, .slomoVideos])
  }
  
  // MARK: - Custom Methods
  
  private func setPhotosPickerItem(for selection: PhotosPickerItem?) {
    guard let selection else { return }
    selection.loadTransferable(type: CustomImageTransfer.self) { [weak self] result in
      guard let self else { return }
      Task {
        switch result {
        case .success(let data):
          if let uiImage = data?.image,
             let attachment = self.attachmentManager.saveImage(uiImage, folderName: self.folderName) {
            self.selectedAttachmentItem = attachment
            DispatchQueue.main.async {
                self.quickLookEdit = true
            }
          }
        case .failure(let error):
          print("Failed to import Image \(error)")
        }
      }
    }
    setVideoPickerItem(for: selection)
  }
  
  private func setVideoPickerItem(for selection: PhotosPickerItem?) {
    guard let selection else { return }
    selection.loadTransferable(type: Movie.self) { [weak self] result in
      guard let self else { return }
      Task {
        switch result {
        case .success(let file):
          if let url = file?.url,
             let attachment = self.attachmentManager.saveFile(
              url, fileType: url.pathExtension, folderName: self.folderName) {
            DispatchQueue.main.async {
              self.attachments.append(attachment)
            }
            // Delete the temp file
            FileManager.default.remove(atURL: url)
          }
        case .failure(let error):
          print("Failed to import Video \(error)")
        }
      }
    }
  }
  
  private struct CustomImageTransfer: Transferable {
    var image: UIImage?
    
    public static var transferRepresentation: some TransferRepresentation {
      DataRepresentation(importedContentType: .image) { data in
        let image = UIImage(data: data) ?? UIImage(systemName: "exclamationmark.square")
        return CustomImageTransfer(image: image)
      }
    }
  }
  
  private struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(contentType: .movie) { movie in
        SentTransferredFile(movie.url)
      } importing: { received in
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: url.path) {
          FileManager.default.remove(atURL: url)
        }
        FileManager.default.copy(atURL: received.file, to: url)
        
        return .init(url: url)
      }
    }
  }
  
  func fileAction(_ result: Result<URL, Error>) {
    switch result {
    case.success(let url):
      if url.startAccessingSecurityScopedResource() {
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          if let attachment = self.attachmentManager.saveFile(
            url, fileType: url.pathExtension, folderName: self.folderName) {
            self.attachments.append(attachment)
          }
        }
        url.stopAccessingSecurityScopedResource()
      } else {
        print("Failed to import file")
      }
      
    case .failure(let error):
      print("Failed import file, Reason: \(error.localizedDescription)")
    }
  }
  
  
  func delete(_ privateID: String?) {
    if let attachment = attachments.first(where: { $0.privateID == privateID }) {
      attachment.delete()
      attachments.removeAll(where: { $0.privateID == privateID })
    }
  }
  
  func addAttachmentItem(for fileName: String? = nil) {
    var attachmentItem: AttachmentItem?
    if let fileName {
      attachmentItem = selectedAttachmentItem?.move(fileName)
    } else {
      attachmentItem = selectedAttachmentItem
    }
    if let attachmentItem {
      DispatchQueue.main.async {
        self.attachments.append(attachmentItem)
      }
    }
    self.selectedAttachmentItem = nil
  }
  
  // MARK: - Camera
  
  func checkAccessForImagePicker() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    guard UIImagePickerController.isSourceTypeAvailable(.camera) &&
           UIImagePickerController.availableCaptureModes(for: .rear) != nil else {
      showPhoto = true
      return
    }
    
    switch status {
    case .authorized:
      showCamera.toggle()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] isEnabled in
          if isEnabled {
            DispatchQueue.main.async {
              self?.showCamera.toggle()
            }
          } else {
            self?.showCameraAlert.toggle()
          }
      }
    case .restricted, .denied:
      self.showCameraAlert.toggle()
      print("You have explicitly denied permission for media capture")
    
    default: break
    }
  }
  
  func openDeviceSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      return
    }
    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, completionHandler: { _ in})
    }
  }
  
  enum SourceType {
    case takePhoto, takeVideo, library
    
    var type: UIImagePickerController.SourceType {
      switch self {
      case .library: return .photoLibrary
      case .takePhoto, .takeVideo: return .camera
      }
    }
  }
}
