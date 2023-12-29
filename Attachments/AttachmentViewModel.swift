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
import Toast

class AttachmentViewModel: ObservableObject {
  
  @Published var showAttachmentDialog = false
  @Published var photoPicker: PhotosPickerItem? {
    didSet {
      setPhotosPickerItem(for: photoPicker)
    }
  }
  @Published var selectedImage: UIImage? {
    didSet {
      handleAttachmentFile(for: .image(selectedImage), isFromImageEdit: true)
    }
  }
  @Published var selectedVideo: URL? {
    didSet {
      handleAttachmentFile(for: .file(selectedVideo))
    }
  }
  
  @Published public var audioAttachmentItem: URL? {
    didSet {
      if let audioAttachmentItem {
        generateAttachmentItem(for: audioAttachmentItem)
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
  @Published var selectedQuickLookItem: URL? {
    didSet {
      if let selectedQuickLookItem {
        quickLookEdit = false
        generateAttachmentItem(for: selectedQuickLookItem)
      }
    }
  }
  
  @Published public var fileName = ""
  @Published public var showFileNameAlert = false
  
  @Published var showToast: ToastMessage?
  
  private (set) var selectedAttachmentItem: AttachmentItem?
  private let fileManager = FileManager.default
  let attachmentManager: AttachmentManager
  
  init(directory: AttachmentManager.AttachmentDirectory = .downloads) {
    self.attachmentManager = .init(directory)
  }
  
  // MARK: - Custom Methods
  
  private func setPhotosPickerItem(for selection: PhotosPickerItem?) {
    guard let selection else { return }
    selection.loadTransferable(type: CustomImageTransfer.self) { [weak self] result in
      guard let self else { return }
      Task {
        switch result {
        case .success(let data):
          if let image = data?.image {
            self.handleAttachmentFile(for: .image(image), isFromImageEdit: true)
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
          if let url = file?.url {
            self.handleAttachmentFile(for: .file(url)) {
              // Delete the temp file
              FileManager.default.remove(atURL: url)
            }
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
        handleAttachmentFile(for: .file(url)) {
          url.stopAccessingSecurityScopedResource()
        }
      } else {
        setToast("Failed to import file")
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
    self.fileName = ""
    self.selectedAttachmentItem = nil
  }
  
  func handleAttachmentFile(for type: AttachmentManager.AttachmentType,
                                     isFromImageEdit: Bool = false,
                                     completion: (() -> Void)? = nil) {
     attachmentManager.handleAttachment(for: type) { [weak self] result in
       switch result {
       case .success(let attachmentItem):
         self?.selectedAttachmentItem = attachmentItem
         DispatchQueue.main.async {
           if isFromImageEdit {
             self?.quickLookEdit = true
           } else {
             self?.showFileNameAlert = true
           }
         }
         completion?()
       case .failure(let error):
         self?.setToast(error.message)
         completion?()
       }
     }
   }
  
  func generateAttachmentItem(for url: URL?) {
    guard let url,
          let attachmentItem = attachmentManager.generateAttachmentItem(for: url) else { return }
    if showFileNameAlert {
      showFileNameAlert = false
    }
    selectedAttachmentItem = attachmentItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.showFileNameAlert = true
    }
  }
  
  func setToast(_ message: String, style: Color = .blue) {
    DispatchQueue.main.async {
      self.showToast = ToastMessage(message, style: style)
    }
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

// MARK: - AttachmentAlertOptions

public enum AttachmentAlertItem: CaseIterable, Identifiable {
  case skip, save
  
  public var title: String {
    switch self {
    case .save: return "Save"
    case .skip: return "Skip"
    }
  }
  public var id: String { title }
}

extension AttachmentViewModel {
  
  func attachmentFileNameAction(for type: AttachmentAlertItem) {
    setFileNameAlert(show: false)
    switch type {
    case .save:
      if !fileName.isEmpty {
        addAttachmentItem(for: fileName)
      } else {
        setFileNameAlert(show: true)
      }
    case .skip:
      addAttachmentItem()
    }
  }
  
  private func setFileNameAlert(show: Bool) {
    DispatchQueue.main.async {
      self.showFileNameAlert = show
    }
  }
}
