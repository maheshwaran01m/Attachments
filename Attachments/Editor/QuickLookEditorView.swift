//
//  QuickLookEditorView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 15/09/23.
//

import SwiftUI
import QuickLook

public struct QuickLookEditorView: UIViewControllerRepresentable {
  
  public typealias Context = UIViewControllerRepresentableContext<Self>
    
  private var canSaveImage: (Bool) -> Void
  
  private let url: URL?
  private var localURL: URL?
  
  public init(_ url: URL?, canSaveImage: @escaping (Bool) -> Void) {
    self.canSaveImage = canSaveImage
    self.url = url
    self.localURL = createCopyOfFile(url)
  }
  
  public func makeUIViewController(context: Context) -> UIViewController {
    let vc = QuickLookEditorVC(for: url, localURL: localURL, canSaveImage: canSaveImage)
    return UINavigationController(rootViewController: vc)
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - QuickLookEditorVC

class QuickLookEditorVC: UIViewController {
  
  private let url: URL?
  private var localURL: URL?
  private var preview: QLPreviewController?
  private var alertController: UIAlertController?
  private var isFromDiscard = false
  
  private var canSaveImage: (Bool) -> Void
  
  init(for url: URL?, localURL: URL?, canSaveImage: @escaping (Bool) -> Void) {
    self.url = url
    self.canSaveImage = canSaveImage
    self.localURL = localURL
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    url = nil
    canSaveImage = { _ in }
    super.init(coder: coder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupQuickLook()
  }
  
  private func setupQuickLook() {
    guard preview == nil else { return }
    let preview = QLPreviewController()
    preview.delegate = self
    preview.dataSource = self
    preview.currentPreviewItemIndex = 0
    self.preview = preview
    setupNavigationBarItems()
    
    navigationController?.present(preview, animated: false)
  }
  
  private func setupNavigationBarItems() {
    let cancelButton = UIBarButtonItem(
      image: UIImage(systemName: "chevron.backward"),
      style: .plain, target: self,
      action: #selector(showDiscardAlert))
    
    preview?.navigationItem.leftBarButtonItem = cancelButton
  }
}

// MARK: - QLPreviewControllerDataSource

extension QuickLookEditorVC: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
  
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }
  
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    PreviewItem(url: localURL, title: localURL?.lastPathComponent ?? "")
  }
  
  // MARK: - QLPreviewControllerDelegate
  
  func previewController(_ controller: QLPreviewController,
                         editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
    .updateContents
  }
  
  func previewControllerWillDismiss(_ controller: QLPreviewController) {
    addAttachmentItem()
  }
}

extension QuickLookEditorVC {
  
  // MARK: - NavigationItem
  
  @objc private func showDiscardAlert() {
    showPopupForDiscardAlert()
  }
  
  @objc private func showSaveAlert() {
    addAttachmentItem()
  }
  
  private func addAttachmentItem() {
    guard !isFromDiscard else { return }
    deleteAttachmentFile()
    canSaveImage(true)
  }
  
  private func dismissVC() {
    canSaveImage(false)
  }
  
  // MARK: - Discard Alert
  
  public func showPopupForDiscardAlert() {
    guard alertController == nil else { return }
    let message = "Attachment File will be discarded. Do you wish to proceed?"
    
    let alert = UIAlertController(
      title: "Warning",
      message: message,
      preferredStyle: .alert)
    
    // Back Button Action
    let proceedAction = UIAlertAction(title: "Proceed",
                                      style: .destructive) { [weak self] _ in
      self?.isFromDiscard = true
      self?.resetAlertController()
      self?.deleteAttachmentFolder()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
      alert.dismiss(animated: true)
      self?.resetAlertController()
    }
    
    alert.addAction(proceedAction)
    alert.preferredAction = proceedAction
    alert.addAction(cancelAction)
    alertController = alert
    preview?.present(alert, animated: true)
  }
  
  private func resetAlertController() {
    alertController = nil
  }
}

extension QuickLookEditorVC {
  
  private func deleteAttachmentFolder() {
    do {
      if let url {
        try FileManager.default.removeItem(at: url.deletingLastPathComponent())
      }
    } catch {
      print("Error While deleting attachmentFile")
    }
    canSaveImage(false)
  }
  
  private func deleteAttachmentFile(completion: (() -> Void)? = nil) {
    do {
      if let url, let oldURL = localURL {
        let newPath = oldURL.path.replacingOccurrences(of: "Copy", with: "")
        
        if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(at: url)
          // Replace original image with edited version of image
          try FileManager.default.moveItem(atPath: oldURL.path, toPath: newPath)
        }
        completion?()
      }
    } catch {
      print("Error While deleting attachmentFile: ")
      completion?()
    }
  }
}

// MARK: - Create a Copy

fileprivate func createCopyOfFile(_ url: URL?) -> URL? {
  guard let url, FileManager.default.fileExists(atPath: url.path) else { return nil }
  do {
    let newPath = url.deletingPathExtension().path + "Copy.\(url.pathExtension)"
    // Clear the existing file before creating copy
    if FileManager.default.fileExists(atPath: newPath) {
      try FileManager.default.removeItem(atPath: newPath)
    }
    try FileManager.default.copyItem(atPath: url.path, toPath: newPath)
    return URL(fileURLWithPath: newPath)
    
  } catch {
    print("Error while creating copy of url: \(url.path)")
    return nil
  }
}

extension QuickLookEditorVC {
  
  // MARK: - PreviewItem
  
  public class PreviewItem: NSObject, QLPreviewItem {
    public var previewItemURL: URL?
    public var previewItemTitle: String?
    
    public init(url: URL?, title: String?) {
      previewItemURL = url
      previewItemTitle = title
    }
  }
}

// MARK: - Coordinator

struct QuickLookCoordinatorView: View {
  
  @SwiftUI.Environment(\.dismiss) private var dismiss

  @Binding var selectedURL: URL?
  @State private var canSaveImage = false
  
  private let url: URL?
  
  public init(_ url: URL?, selectedURL: Binding<URL?>) {
    _selectedURL = selectedURL
    self.url = url
  }
  
  var body: some View {
    QuickLookEditorView(url) { canSaveImage in
      self.canSaveImage = canSaveImage
      dismiss()
    }
    .onDisappear(perform: updateAttachmentURL)
  }
  
  private func updateAttachmentURL() {
    guard canSaveImage, let url else { return }
    selectedURL = url
  }
}
