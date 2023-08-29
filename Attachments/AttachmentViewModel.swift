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
  @Published var showVideo = false
  @Published var showPhoto = false
  @Published var showFiles = false
  @Published var attachments: [AttachmentItem] = []
  
  private let fileManager = FileManager.default
  private let attachmentManager = AttachmentManager()
  
  var allowedFileType: [UTType] {
    [.image, .video, .movie, .pdf, .text, .plainText, .spreadsheet, .presentation]
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
             let attachment = self.attachmentManager.saveImage(uiImage, folderName: "Files") {
            DispatchQueue.main.async {
              self.attachments.append(attachment)
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
              url, fileType: url.pathExtension, folderName: "Files") {
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
      if url.startAccessingSecurityScopedResource(),
          let attachment = self.attachmentManager.saveFile(
        url, fileType: url.pathExtension, folderName: "Files") {
        DispatchQueue.main.async {
          self.attachments.append(attachment)
        }
        url.stopAccessingSecurityScopedResource()
      } else {
        print("Failed to import file")
      }
      
    case .failure(let error):
      print("Failed import file, Reason: \(error.localizedDescription)")
    }
  }
  
  
  func delete(_ privateID: String) {
    if let attachment = attachments.first(where: { $0.privateID == privateID }) {
      attachment.delete()
      attachments.removeAll(where: { $0.privateID == privateID })
    }
  }
}

