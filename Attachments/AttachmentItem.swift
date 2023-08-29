//
//  AttachmentItem.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import Foundation
import UIKit.UIImage
import UniformTypeIdentifiers

struct AttachmentItem {
  var id: String?
  var privateID: String
  var fileName: String?
  var fileExtension: String?
  var folderName: String?
  var url: URL?
  var localPath: String?
  var createdDate: String?
  var image: UIImage?
  
  var directory: URL {
    let directory = URL.documentsDirectory
    guard let folderName else { return directory }
    let finalPath = directory.appending(path: folderName)
      .appending(path: id ?? privateID)
    
    return finalPath
  }
  
  var localFilePath: String {
    guard let fileName, let fileExtension else {
      return directory.path()
    }
    let filePath = directory
      .appending(path: fileName)
      .appendingPathExtension(fileExtension)
    
    guard FileManager.default.fileExists(filePath) else {
      return directory.path()
    }
    return filePath.path()
  }
  
  var isSavedLocally: Bool {
    FileManager.default.fileExists(atPath: localPath ?? localFilePath)
  }
  
  var getPlaceholderImage: UIImage {
    let placeholder = { () -> UIImage in
      let extn = fileExtension ?? "exclamationmark.triangle"
      return UIImage(contentsOfFile: localFilePath) ?? defaultImage(for: extn)
    }
    guard let localPath, let image = UIImage(contentsOfFile: localPath) else {
      return placeholder()
    }
    return image
  }
  
  func delete(completion: (() -> Void)? = nil) {
    let url = URL(filePath: localPath ?? localFilePath)
    if FileManager.default.fileExists(url) {
      FileManager.default.remove(atURL: url.deletingLastPathComponent())
    } else {
      print("Failed to delete the file at URL: \(url)")
      completion?()
    }
  }
  
  func move(_ fileName: String) -> Self? {
    var attachment = self
    if let url = attachment.url {
      let extn = url.pathExtension
      let newURL = url.deletingLastPathComponent().appending(path: fileName).appendingPathExtension(extn)
      FileManager.default.move(atURL: url, to: newURL)
      attachment.url = newURL
    }
    return attachment
  }
  
  func defaultImage(for value: String?) -> UIImage {
    var string: String?
    
    if let type = UTType(filenameExtension: value ?? "") {
      switch type {
      case .movie, .mpeg4Movie, .mpeg, .mpeg2Video,
          .video, .quickTimeMovie: string = "camera.on.rectangle"
      case .pdf: string =  "doc"
      case .mp3, .wav: string = "dot.radiowaves.left.and.right"
      default: string = "exclamationmark.triangle"
      }
    }
    return .init(systemName: string ?? "exclamationmark.triangle")!
  }
}

struct AttachmentManager {
  
  private let fileManager = FileManager.default
  private let documentURL = URL.documentsDirectory
  
  private func attachmentFolder(for folderName: String? = nil, privateID: String) -> URL? {
    if let folderName {
      return FileManager.default.create(named: privateID, folder: folderName)
    }
    return FileManager.default.create(named: privateID, folder: folderName ?? UUID().uuidString)
  }
  
  func saveImage(_ image: UIImage, fileName: String? = nil, folderName: String?,
                 privateID: String = UUID().uuidString) -> AttachmentItem? {
    
    guard let folderURL = attachmentFolder(for: folderName, privateID: privateID),
          let jpgData = image.jpegData(compressionQuality: 0.8) else {
      return nil
    }
    let fileName = fileName ?? "Image"
    var finalURL = folderURL.appending(path: fileName)
    finalURL.appendPathExtension(for: .jpeg)
    
    fileManager.write(jpgData, atURL: finalURL)
    
    return .init(privateID: privateID, fileName: fileName, fileExtension: "jpeg",
                 folderName: folderName, url: finalURL, localPath: finalURL.path())
  }
  
  func saveFile(_ fileURL: URL, fileName: String? = nil, fileType: String?,
                folderName: String?, privateID: String = UUID().uuidString) -> AttachmentItem? {
    guard let folderURL = attachmentFolder(for: folderName, privateID: privateID) else {
      return nil
    }
    let fileName = fileName ?? fileURL.deletingPathExtension().lastPathComponent
    let finalURL = folderURL.appending(path: fileName).appendingPathExtension(fileURL.pathExtension)
    
    do {
      let data = try Data(contentsOf: fileURL)
      fileManager.write(data, atURL: finalURL)
    } catch {
      print("Failed to convert data from URL: \(fileURL)")
    }
    return .init(privateID: privateID, fileName: fileName, fileExtension: fileURL.pathExtension,
                 folderName: folderName, url: finalURL, localPath: finalURL.path())
  }
}
