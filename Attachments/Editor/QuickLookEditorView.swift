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
  
  @Environment(\.dismiss) private var dismiss
  @Binding var selectedURL: URL?
  @Binding var isPresented: Bool
  
  private let url: URL?
  private var localURL: URL?
  private let preview = QLPreviewController()
  
  public init(isPresented: Binding<Bool>, url: URL?, selectedURL: Binding<URL?>) {
    _isPresented = isPresented
    _selectedURL = selectedURL
    self.url = url
  }
  
  public func makeUIViewController(context: Context) -> UIViewController {
    let vc = QuickLookViewController(url) { url in
      selectedURL = url
      dismiss()
    }
    return UINavigationController(rootViewController: vc)
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

// MARK: - QuickLookViewController

class QuickLookViewController: QLPreviewController {
  
  private var selectedURL: (URL?) -> Void
  private let url: URL?
  private var localURL: URL?
  private var alertController: UIAlertController?
  
  lazy var cancelButton: UIBarButtonItem = {
    .init(image: UIImage(systemName: "chevron.backward"),
          style: .plain, target: self, action: #selector(showDiscardAlert))
  }()
  
  lazy var saveButton: UIBarButtonItem = {
    .init(title: "Save", style: .plain, target: self,
          action: #selector(showSaveAlert))
  }()
  
  init(_ url: URL?, selectedURL: @escaping (URL?) -> Void) {
    self.url = url
    self.selectedURL = selectedURL
    super.init(nibName: nil, bundle: nil)
    self.localURL = createCopyOfFile(url)
    setupQuickLook()
    setupNavigationBarItems()
  }
  
  required init?(coder: NSCoder) {
    self.selectedURL = { _ in }
    self.url = nil
    super.init(coder: coder)
  }
  
  private func setupQuickLook() {
    self.delegate = self
    self.dataSource = self
    self.currentPreviewItemIndex = 0
  }
  
  private func setupNavigationBarItems() {
    if let rightBarButtons = self.navigationItem.rightBarButtonItems,
       !rightBarButtons.isEmpty, rightBarButtons.contains(
        where: { $0.image?.description.contains("pencil.tip.crop.circle.on") ?? false }) {
      self.navigationItem.rightBarButtonItems?.removeAll(where: { $0 == saveButton })
    } else {
      self.navigationItem.rightBarButtonItem = saveButton
    }
    self.navigationItem.leftBarButtonItem = cancelButton
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    setupNavigationBarItems()
  }
}

// MARK: - NavigationItem

extension QuickLookViewController {
  
  @objc private func showDiscardAlert() {
    showPopupForDiscardAlert()
  }
  
  @objc private func showSaveAlert() {
    addAttachmentItem()
  }
  
  private func clearButtonClicked() {
    localURL = createCopyOfFile(url)
    self.reloadData()
  }
  
  private func addAttachmentItem() {
    deleteAttachmentFile()
    selectedURL(url)
  }
}

// MARK: - Discard Alert

extension QuickLookViewController {
  
  public func showPopupForDiscardAlert() {
    guard alertController == nil else { return }
    let message = "Attachment File will be discarded. Do you wish to proceed?"
    alertController = UIAlertController(
      title: "Warning",
      message: message,
      preferredStyle: .alert)
    
    // Back Button Action
    let proceedAction = UIAlertAction(title: "Proceed",
                                      style: .destructive) { [weak self] _ in
      self?.deleteAttachmentFolder()
      self?.alertController = nil
    }
    
    let discardAction = UIAlertAction(title: "Discard Changes", style: .default) { [weak self] _ in
      self?.clearButtonClicked()
      self?.alertController = nil
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
      self?.alertController?.dismiss(animated: true)
      self?.alertController = nil
    }
    alertController?.addAction(proceedAction)
    alertController?.addAction(discardAction)
    alertController?.preferredAction = proceedAction
    
    alertController?.addAction(cancelAction)
    guard let alertController else { return }
    self.present(alertController, animated: true)
  }
}

extension QuickLookViewController {
  
  private func deleteAttachmentFolder() {
    do {
      if let url {
        try FileManager.default.removeItem(at: url.deletingLastPathComponent())
      }
    } catch {
      print("Error While deleting attachmentFile: ")
    }
    selectedURL(nil)
  }
  
  private func deleteAttachmentFile(completion: (() -> Void)? = nil) {
    do {
      if let url, let oldURL = localURL {
        let newPath = oldURL.path().replacingOccurrences(of: "Copy", with: "")
        
        if FileManager.default.fileExists(atPath: url.path()) {
          try FileManager.default.removeItem(at: url)
          // Replace original image with edited version of image
          try FileManager.default.moveItem(atPath: oldURL.path(), toPath: newPath)
        }
        completion?()
      }
    } catch {
      print("Error While deleting attachmentFile: ")
      completion?()
    }
  }
}

// MARK: - QLPreviewControllerDataSource

extension QuickLookViewController: QLPreviewControllerDataSource {
  
  public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }
  
  public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    PreviewItem(url: localURL, title: localURL?.lastPathComponent ?? "")
  }
}

// MARK: - QLPreviewControllerDelegate

extension QuickLookViewController: QLPreviewControllerDelegate {
  
  public func previewController(
    _ controller: QLPreviewController,
    editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
      .updateContents
    }
}

// MARK: - PreviewItem

extension QuickLookViewController {
  
  public class PreviewItem: NSObject, QLPreviewItem {
    public var previewItemURL: URL?
    public var previewItemTitle: String?
    
    public init(url: URL?, title: String?) {
      previewItemURL = url
      previewItemTitle = title
    }
  }
}

// MARK: - Create a Copy

extension QuickLookViewController {
  
  public func createCopyOfFile(_ url: URL?) -> URL? {
    guard let url, FileManager.default.fileExists(atPath: url.path()) else { return nil }
    do {
      let newPath = url.deletingPathExtension().path() + "Copy.\(url.pathExtension)"
      // Clear the existing file before creating copy
      if FileManager.default.fileExists(atPath: newPath) {
        try FileManager.default.removeItem(atPath: newPath)
      }
      FileManager.default.copy(atPath: url.path(), to: newPath)
      return URL(filePath: newPath)
      
    } catch {
      print("Error while creating copy of url: \(url.path())")
      return nil
    }
  }
}
