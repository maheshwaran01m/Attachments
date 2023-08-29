//
//  AttachmentDetailView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import SwiftUI

public struct AttachmentDetailView: View {
  
  private var imageSize: ImageSize = .size40
  private var style: Style = .onlyTitle
  private var title: String
  private var image: Image
  private var deleteAction: () -> Void
  private var isDownloadEnabled: Bool = false
  private var downloadAction: (() -> Void)?
  private var iconColor: Color = .primary
  
  public init(_ title: String,
              image: Image,
              style: AttachmentDetailView.Style = .onlyTitle,
              deleteAction: @escaping () -> Void) {
    self.title = title
    self.image = image
    self.style = style
    self.deleteAction = deleteAction
  }
  
  public var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: 8) {
        imageView
        mainView
      }
      if isDownloadEnabled {
        iconView("arrow.down.circle") { downloadAction?() }
      }
      iconView("trash", action: deleteAction)
    }
    .frame(height: 40)
  }
  
  private var mainView: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch style {
      case .onlyTitle: titleView(title)
      case .withDescription(let desc):
        titleView(title)
        detailView(desc)
      }
    }
  }
  
  private var imageView: some View {
    image
      .resizable()
      .frame(width: imageSize.width, height: 30)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
  
  private func iconView(_ icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: icon)
    }
    .foregroundColor(Color.primary)
    .buttonStyle(.borderless)
    .padding(10)
  }
  
  private func titleView(_ title: String) -> some View {
    Text(title)
      .foregroundStyle(Color.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(height: 18)
  }
  
  private func detailView(_ title: String) -> some View {
    Text(title)
      .foregroundStyle(Color.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(height: 14)
  }
  
}

public extension AttachmentDetailView {
  
  enum Style {
    case onlyTitle
    case withDescription(String)
  }
  
  enum ImageSize {
    case size40
    case size60
    
    var width: CGFloat {
      switch self {
      case .size40: return 52
      case .size60: return 53
      }
    }
  }
  
  func imageSize(_ imageSize: ImageSize) -> Self {
    var newView = self
    newView.imageSize = imageSize
    return newView
  }
  
  func download(_ show: Bool, action: @escaping () -> Void) -> Self {
    var newView = self
    newView.isDownloadEnabled = show
    newView.downloadAction = action
    return newView
  }
  
  func iconColor(_ iconColor: Color) -> Self {
    var newView = self
    newView.iconColor = iconColor
    return newView
  }
}

struct AttachmentDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AttachmentDetailView("Hello", image: .init(systemName: "laptopcomputer"),
                      style: .withDescription("Example")) {}
      .download(true, action: {})
      .padding(.horizontal, 20)
  }
}
