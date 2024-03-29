//
//  AttachmentItem.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import Foundation
import UIKit.UIImage
import UniformTypeIdentifiers
import QuickLook

struct AttachmentItem {
  var id: String?
  var privateID: String?
  var fileName: String?
  var fileExtension: String?
  var folderPath: String?
  var url: URL?
  var localPath: String?
  var createdDate: String?
  var image: UIImage?
  
  var directory: String {
    let directory = URL.documentsDirectory
    guard let folderPath, let id = id ?? privateID else { return directory.path() }
    let finalPath = directory.path() + folderPath + "/\(id)"
    
    return finalPath
  }
  
  var localFilePath: String {
    if let localPath {
      if FileManager.default.fileExists(atPath: localPath) {
        return localPath
      } else {
        let split = localPath.split(separator: "Documents/")
        let filePath = URL.documentsDirectory.path() + split[1]
        return filePath
      }
    } else {
      guard let fileName, let fileExtension else {
        return directory
      }
      let filePath = directory + "/\(fileName).\(fileExtension)"
      guard FileManager.default.fileExists(atPath: filePath) else {
        return directory
      }
      return filePath
    }
  }
  
  var isSavedLocally: Bool {
    FileManager.default.fileExists(atPath: localFilePath)
  }
  
  var getPlaceholderImage: UIImage {
    let placeholder = { () -> UIImage in
      return .init(systemName: defaultIcon)!
    }
    guard let image = UIImage(contentsOfFile: localFilePath) else {
      return placeholder()
    }
    return image
  }
  
  public var getThumbImage: AttachmentDetailView.ImageStyle {
    let placeholder = { () -> AttachmentDetailView.ImageStyle in
      if let image = UIImage(contentsOfFile: localFilePath) {
        return .image(.init(uiImage: image))
      }
      return .icon(defaultIcon)
    }
    guard let localPath, let image = UIImage(contentsOfFile: localPath) else {
      return placeholder()
    }
    return .image(.init(uiImage: image))
  }
  
  public func delete(completion: (() -> Void)? = nil) {
    if FileManager.default.fileExists(atPath: localFilePath) {
      let url = URL(filePath: localFilePath).deletingLastPathComponent()
      FileManager.default.remove(atURL: url)
      completion?()
    } else {
      print("Failed to delete the file at Path: \(localFilePath)")
      completion?()
    }
  }
  
  func move(_ fileName: String) -> Self? {
    if let localPath {
      let url = URL(filePath: localPath)
      let oldURL = url.deletingLastPathComponent().path()
      let newFilePath = oldURL + fileName + "." + url.pathExtension
      
      do {
        let oldPath = url.deletingLastPathComponent().path() + (self.fileName ?? url.lastPathComponent)
        try FileManager.default.moveItem(atPath: oldPath, toPath: newFilePath)
        
        if FileManager.default.fileExists(atPath: newFilePath) {
          var attachment = self
          attachment.localPath = newFilePath
          attachment.fileName = fileName
          return attachment
        }
      } catch {
        print("""
              Failed to move for URL: \(url),
              Reason: \(error.localizedDescription)
              """)
        return nil
      }
    }
    return nil
  }
  
  var defaultIcon: String {
    var string: String?
    
    if let type = UTType(filenameExtension: fileExtension?.lowercased() ?? "") {
      switch type {
      case .movie, .mpeg4Movie, .mpeg, .mpeg2Video,
          .video, .quickTimeMovie: string = "video"
      case .pdf: string =  "doc"
      case .mp3, .wav, .mpeg4Audio, .audio: string = "dot.radiowaves.left.and.right"
      case .text, .plainText, .rtf: string = "doc.text"
      default:
        if string == UTType(filenameExtension: "m4a")?.description {
          string = "dot.radiowaves.left.and.right"
        } else {
          string = "questionmark.folder"
        }
      }
    }
    return string ?? "questionmark.folder"
  }
  
  func generateThumbnail(_ completion: @escaping (UIImage) -> Void)  {
    let request = QLThumbnailGenerator.Request(
      fileAt: URL(filePath: localFilePath),
      size: .init(width: 53, height: 40),
      scale: UIScreen.main.scale,
      representationTypes: .all)
    
    let generator = QLThumbnailGenerator.shared
    generator.generateRepresentations(for: request) { thumb, type, error in
      if let thumb {
        DispatchQueue.main.async {
          completion(thumb.uiImage)
        }
        
      } else if let error {
        print("Error while generating thumbnail: \(error)")
      }
    }
  }
}
