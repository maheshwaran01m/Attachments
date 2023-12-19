//
//  AttachmentFormat.swift
//  Attachments
//
//  Created by MAHESHWARAN on 19/12/23.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

extension AttachmentManager {
  
  static let videoFileFormats: [UTType] = [.movie, .video, .mpeg4Movie,
                                           .init(filenameExtension: "mp4") ?? .movie,
                                           .init(filenameExtension: "mov") ?? .movie ]
  
  static let audioFileFormats: [UTType] = [.audio, .wav, .mpeg4Audio,
                                           .init(filenameExtension: "m4a") ?? .mpeg4Audio,
                                           .init(filenameExtension: "aac") ?? .mpeg4Audio]
  
  static let imageFileFormats = [UTType.png, .jpeg, .gif, .bmp, .svg].map { $0.identifier }
  
  var allowedPhotoLibraryType: PHPickerFilter {
    .any(of: [.images, .screenshots, .depthEffectPhotos,
              .videos, .screenRecordings, .slomoVideos])
  }
  
  var allowedFileType: [UTType] {
    [.image, .video, .movie, .pdf, .text, .plainText, .spreadsheet, .svg, .audio, .bmp,
     .presentation, .zip, .gif, .wav, .rtf, .mp3, .jpeg, .png, .mpeg4Movie, .mpeg4Audio,
     .wav, .init(filenameExtension: "docx") ?? .pdf, .init(filenameExtension: "doc") ?? .pdf,
     .init(filenameExtension: "xls") ?? .spreadsheet, .init(filenameExtension: "xlsx") ?? .spreadsheet,
     .init(filenameExtension: "pptx") ?? .presentation, .init(filenameExtension: "mov") ?? .movie,
     .init(filenameExtension: "m4a") ?? .mpeg4Audio, .init(filenameExtension: "aac") ?? .mpeg4Audio,
     .init(filenameExtension: "jpg") ?? .image]
  }
}

