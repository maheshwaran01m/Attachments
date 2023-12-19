//
//  ImageEditorView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 13/09/23.
//

import SwiftUI
import PencilKit

struct ImageEditorView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @State private var canvas = PKCanvasView()
  @Binding private var image: UIImage?
  @State private var toolPicker = PKToolPicker()
  
  
  init(image: Binding<UIImage?>) {
    _image = image
  }
  
  var body: some View {
    ZStack {
      GeometryReader { proxy in
        let size = proxy.frame(in: .global).size
        ZStack {
          CanvasView($canvas, image: $image,
                     toolPicker: $toolPicker, size: size)
        }
        .toolbar {
          saveButton(proxy.frame(in: .global))
        }
        .background(.gray.opacity(0.3))
      }
    }
  }
  
  func saveButton(_ rect: CGRect) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Save") { saveImage(rect) }
    }
  }
  
  func saveImage(_ rect: CGRect) {
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 1)
    canvas.drawHierarchy(in: .init(origin: .zero, size: rect.size), afterScreenUpdates: true)
    let generateImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    if let image = generateImage {
      self.image = image
      dismiss()
    } else {
      dismiss()
    }
  }
}

struct ImageEditorView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ImageEditorView(image: .constant(.init(systemName: "star")))
    }
  }
}

struct CanvasView: UIViewRepresentable {
  
  @Binding var canvas: PKCanvasView
  @Binding var image: UIImage?
  @Binding var toolPicker: PKToolPicker
  
  var size: CGSize
  
  init(_ canvas: Binding<PKCanvasView>, image: Binding<UIImage?>, toolPicker: Binding<PKToolPicker>, size: CGSize) {
    _canvas = canvas
    _image = image
    _toolPicker = toolPicker
    self.size = size
  }
  
  func makeUIView(context: Context) -> PKCanvasView {
    canvas.isOpaque = false
    canvas.backgroundColor = .clear
    canvas.drawingPolicy = .anyInput
    
    if let image {
      let imageView = UIImageView(image: image)
      imageView.frame = .init(x: 0, y: 0, width: size.width,
                              height: size.height)
      imageView.contentMode = .scaleAspectFit
      imageView.clipsToBounds = true
      
      let subView = canvas.subviews[0]
      subView.addSubview(imageView)
      subView.sendSubviewToBack(imageView)
      
      toolPicker.setVisible(true, forFirstResponder: canvas)
      toolPicker.addObserver(canvas)
      canvas.becomeFirstResponder()
    }
    return canvas
  }
  
  func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
