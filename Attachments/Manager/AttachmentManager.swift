//
//  AttachmentManager.swift
//  Attachments
//
//  Created by MAHESHWARAN on 19/12/23.
//

import UIKit

struct AttachmentManager {
  
  private let directory: AttachmentDirectory
  
  public init(_ directory: AttachmentDirectory) {
    self.directory = directory
  }
  
  public func attachmentFolder(for privateID: String) -> URL? {
    return FileManager.default.create(named: privateID, folder: directory.path)
  }
  
  public func saveImage(_ image: UIImage, fileName: String? = nil,
                        privateID: String = UUID().uuidString) throws -> AttachmentItem? {
    
    guard let jpgData = image.jpegData(compressionQuality: 0.8) else {
      throw AttachmentError.compressionFailed
    }
    guard let folderURL = attachmentFolder(for: privateID) else {
      throw AttachmentError.destinationFolderNotFound
    }
    let fileName = (fileName ?? "image") + ".jpeg"
    let finalPath = folderURL.path() + "/" + fileName
    do {
      try writeAttachmentData(jpgData, atPath: finalPath)
    } catch {
      print("Failed to convert data from Image: \(finalPath)")
      throw AttachmentError.failedToSaveFile
    }
    
    return .init(privateID: privateID, fileName: fileName, fileExtension: "jpeg",
                 folderPath: directory.path, localPath: finalPath)
  }
  
  public func saveFile(_ fileURL: URL, fileName: String? = nil,
                       privateID: String = UUID().uuidString) throws -> AttachmentItem? {
    guard let folderURL = attachmentFolder(for: privateID) else {
      throw AttachmentError.destinationFolderNotFound
    }
    let fileName = fileName ?? fileURL.deletingPathExtension().lastPathComponent
    let extn = fileURL.pathExtension.lowercased()
    let fileNameWithExtn = fileName + "." + extn
    let finalPath = folderURL.path() + "/" + fileNameWithExtn
      
    do {
      let data = try Data(contentsOf: fileURL)
      try writeAttachmentData(data, atPath: finalPath)
    } catch {
      print("Failed to convert data from URL: \(fileURL)")
      throw AttachmentError.failedToSaveFile
    }
    return .init(privateID: privateID, fileName: fileNameWithExtn, fileExtension: extn,
                 folderPath: directory.path, localPath: finalPath)
  }
  
  var getTimeStamp: String {
    return String(describing: Int64(Date().timeIntervalSince1970 * 1000))
  }
  
  func generateAttachmentItem(for url: URL) -> AttachmentItem? {
    let privateID = url.deletingPathExtension().deletingLastPathComponent().lastPathComponent
    let fileName = url.deletingPathExtension().lastPathComponent
    let extn = url.pathExtension.lowercased()
    
    return .init(
     privateID: privateID,
     fileName: fileName + ".\(extn)",
     fileExtension: extn,
     folderPath: directory.path,
     localPath: url.path())
  }
  
  public enum AttachmentType {
    case image(UIImage?), file(URL?)
  }
  
  func handleAttachment(for type: AttachmentType, fileName: String? = nil,
                        completion: @escaping ((Result<AttachmentItem?, AttachmentError>) -> Void)) {
    switch type {
    case .image(let image):
      guard let image else {
        completion(.failure(.fileNotFound))
        return
      }
      do {
        if let attachment = try saveImage(image, fileName: fileName) {
          completion(.success(attachment))
        } else {
          completion(.failure(.failedToAttach))
        }
      } catch {
        completion(.failure(.failedToSaveFile))
      }
      
    case .file(let url):
      guard let url else {
        completion(.failure(.fileNotFound))
        return
      }
      do {
        try validateSizeForFile(at: url)
        
        if let attachment = try saveFile(url, fileName: fileName) {
          completion(.success(attachment))
        } else {
          completion(.failure(.failedToAttach))
        }
      } catch {
        completion(.failure(handleFileValidationError(error)))
      }
    }
  }
}

extension AttachmentManager {
  
  // MARK: - Write
  
  private func writeAttachmentData(_ data: Data, atPath path: String) throws {
    do {
      if !FileManager.default.fileExists(atPath: path) {
        try data.write(to: URL(filePath: path), options: [.atomic])
        print("Saved an attachment at: \(path)")
      }
    } catch let err {
      print("""
            Failed to save an attachment at: \(path),
            reason: \(err.localizedDescription)
            """)
      throw AttachmentError.failedToSaveFile
    }
  }
}

extension AttachmentManager {
  
  public enum AttachmentDirectory {
    
    case downloads, cache
    
    public var path: String {
      var path: String
      switch self {
      case .cache:
        path = "Cache"
      case .downloads:
        path = "Downloads"
      }
      return path
    }
  }
}
