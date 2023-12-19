//
//  AttachmentError.swift
//  Attachments
//
//  Created by MAHESHWARAN on 19/12/23.
//

import Foundation

extension AttachmentManager {
  
  // MARK: - Validation
  
  enum AttachmentError: Error {
    case fileSizeLimitExceeded(AttachmentFileType), fileNotFound, failedToAttach,
         failedToSaveFile, unknown, destinationFolderNotFound, compressionFailed,
         fileAttributesNotFound
    
    var message: String {
      switch self {
      case .failedToAttach, .failedToSaveFile, .unknown, .fileAttributesNotFound:
        return "Failed to add attachment!\n Try again or contact support."
      
      case .fileNotFound:
        return "File Not Found"
        
      case .fileSizeLimitExceeded(let type):
        return "The file size of the attachment exceeded its maximum limit of \(type.allowedSizeInMB) MB."
      
      case .destinationFolderNotFound:
        return "Attachments Folder was not found"
      case .compressionFailed:
        return "Image failed to convert into JPEG Data with compression"
      }
    }
  }
  
  enum FileValidationError: Error {
    case fileNotFound
    case fileSizeExceeded(AttachmentFileType)
    case fileAttributesNotFound
  }
  
  func validateSizeForFile(at url: URL) throws {
    let resourceKeys = Set<URLResourceKey>(arrayLiteral: URLResourceKey.fileSizeKey,
                                           URLResourceKey.typeIdentifierKey)
    let resourceValues = try url.resourceValues(forKeys: resourceKeys)
    
    guard let sizeInBytes = resourceValues.fileSize,
          let fileTypeString = resourceValues.typeIdentifier else {
      throw AttachmentError.fileAttributesNotFound
    }
    
    let fileType = AttachmentFileType(uti: fileTypeString.lowercased())
    
    if sizeInBytes > fileType.allowedSize {
      throw AttachmentError.fileSizeLimitExceeded(fileType)
    }
  }
  
  func handleFileValidationError(_ error: Error) -> AttachmentError {
    guard let error = error as? FileValidationError else {
      return .unknown
    }
    switch error {
    case .fileSizeExceeded(let fileType):
      let maxSize = fileType.allowedSize
      print("Attempt to attach file larger than expected size: \(maxSize) MB")
      return .fileSizeLimitExceeded(fileType)
      
    case .fileNotFound, .fileAttributesNotFound:
      return .fileNotFound
    }
  }
}

