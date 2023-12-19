//
//  AttachmentFileType.swift
//  Attachments
//
//  Created by MAHESHWARAN on 19/12/23.
//

import Foundation

extension AttachmentManager {
  
  enum AttachmentFileType: String {
    case video, audio, image, document
    
    init(uti: String) {
      if imageFileFormats.contains(uti) {
        self = .image
      } else if audioFileFormats.map({ $0.identifier }).contains(uti) {
        self = .audio
      } else if videoFileFormats.map({ $0.identifier }).contains(uti) {
        self = .video
      } else {
        self = .document
      }
    }
    
    var allowedSize: Int {
      switch self {
      case .video:
        return allowedSizeInMB * (1024 * 1024)
      case .image, .document, .audio:
        return allowedSizeInMB * (1024 * 1024)
      }
    }
    
    var allowedSizeInMB: Int {
      switch self {
      case .video: return 50
      case .image, .document, .audio: return 10
      }
    }
  }
}

