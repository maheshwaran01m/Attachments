//
//  AttachmentItem.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import Foundation
import UIKit.UIImage

struct AttachmentItem {
  var id: String?
  var privateID: String?
  var fileName: String?
  var fileExtension: String?
  var folderName: String?
  var url: URL?
  var localPath: String?
  var createdDate: String?
  var image: UIImage?
  
  var directory: String {
    let filePath = URL.documentsDirectory.appending(path: folderName ?? "")
    guard let folderPath = id ?? privateID, !folderPath.isEmpty else {
      return filePath.path()
    }
    let finalPath = filePath.appending(path: folderPath).path() + "/"
    return finalPath
  }
  
  var localFilePath: String {
    guard let fileName else { return directory }
    return directory + fileName + ".\(fileExtension ?? "")"
  }
  
  var isSavedLocally: Bool {
    FileManager.default.fileExists(atPath: localPath ?? localFilePath)
  }
  
  var getPlaceholderImage: UIImage {
    let placeholder = { () -> UIImage in
      let image = fileExtension ?? "exclamationmark.triangle"
      return UIImage(contentsOfFile: localFilePath) ?? UIImage(named: image) ?? UIImage(systemName: image)!
    }
    guard let localPath, let image = UIImage(contentsOfFile: localPath) else {
      return placeholder()
    }
    return image
  }
  
  func delete(completion: (() -> Void)? = nil) {
    let url = URL(filePath: localPath ?? localFilePath)
    if FileManager.default.fileExists(url) {
      FileManager.default.remove(atURL: url)
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
