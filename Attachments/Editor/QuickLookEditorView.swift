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
  
  private let url: URL?
  private var localURL: URL?
  
  public init(_ url: URL?, selectedURL: Binding<URL?>) {
    _selectedURL = selectedURL
    self.url = url
    self.localURL = createCopyOfFile(url)
  }
  
  public func makeUIViewController(context: Context) -> UIViewController {
    return UINavigationController(rootViewController: QuickLookCoordinator(self))
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
  
  public class QuickLookCoordinator: QLPreviewController,
                                     QLPreviewControllerDataSource,
                                     QLPreviewControllerDelegate {
    
    public var parentView: QuickLookEditorView
    
    public init(_ parentView: QuickLookEditorView) {
      self.parentView = parentView
      super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
      parentView = .init(nil, selectedURL: .constant(.none))
      super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
      super.viewDidLoad()
      setupQuickLook()
    }
    
    public override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      setupNavigationBarItems()
    }
    
    private func setupQuickLook() {
      self.delegate = self
      self.dataSource = self
      self.currentPreviewItemIndex = 0
    }
    
    private func setupNavigationBarItems() {
      
      let cancelButton = UIBarButtonItem(
        image: UIImage(systemName: "chevron.backward"),
        style: .plain, target: self,
        action: #selector(showDiscardAlert))
      
      let saveButton = UIBarButtonItem(
        title: "Save", style: .plain, target: self,
        action: #selector(showSaveAlert))
      
      if self.navigationItem.leftBarButtonItem == nil {
        self.navigationItem.leftBarButtonItem = cancelButton
      }
      checkAndUpdate(saveButton)
    }
    
    private func checkAndUpdate(_ saveButton: UIBarButtonItem) {
      
      guard let rightBarButtons = navigationItem.rightBarButtonItems,
            !rightBarButtons.isEmpty else {
        if navigationItem.rightBarButtonItem == nil {
          navigationItem.rightBarButtonItem = saveButton
        }
        return
      }
      
      if navigationItem.rightBarButtonItem?.title != saveButton.title &&
          !(navigationItem.rightBarButtonItems?.contains(where: { $0.title == saveButton.title }) ?? false) {
        navigationItem.rightBarButtonItems?.append(saveButton)
      }
      guard let editIcon = rightBarButtons.first(
        where: { $0.accessibilityIdentifier == "QLOverlayMarkupButtonAccessibilityIdentifier"}) else {
        return
      }
      guard let image = editIcon.image else { return }
      
      if image.description.contains("pencil.tip.crop.circle.on") {
        navigationItem.rightBarButtonItems?.removeAll(where: { $0.title == saveButton.title })
      } else {
        guard !image.description.contains("pencil.tip.crop.circle") else {
          return
        }
        print("Error while editing: \(QuickLookEditError.editIconNotFound)")
      }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      PreviewItem(url: parentView.localURL, title: parentView.localURL?.lastPathComponent ?? "")
    }
    
    // MARK: - QLPreviewControllerDelegate
    
    public func previewController(_ controller: QLPreviewController,
                                  editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
      .updateContents
    }
    
    // MARK: - NavigationItem
    
    @objc private func showDiscardAlert() {
      showPopupForDiscardAlert()
    }
    
    @objc private func showSaveAlert() {
      addAttachmentItem()
    }
    
    private func clearButtonClicked() {
      parentView.localURL = parentView.createCopyOfFile(parentView.url)
      self.reloadData()
    }
    
    private func addAttachmentItem() {
      deleteAttachmentFile()
      parentView.selectedURL = parentView.url
      parentView.dismiss()
    }
    
    // MARK: - Discard Alert
    
    public func showPopupForDiscardAlert() {
      let message = "Attachment File will be discarded. Do you wish to proceed?"
      
      let alert = UIAlertController(
        title: "Warning",
        message: message,
        preferredStyle: .alert)
      
      // Back Button Action
      let proceedAction = UIAlertAction(title: "Proceed",
                                        style: .destructive) { [weak self] _ in
        self?.deleteAttachmentFolder()
      }
      
      let discardAction = UIAlertAction(title: "Discard Changes", style: .default) { [weak self] _ in
        self?.clearButtonClicked()
      }
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        alert.dismiss(animated: true)
      }
      
      alert.addAction(proceedAction)
      alert.addAction(discardAction)
      alert.preferredAction = proceedAction
      alert.addAction(cancelAction)
      
      self.present(alert, animated: true)
    }
    
    private func deleteAttachmentFolder() {
      do {
        if let url = parentView.url {
          try FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
      } catch {
        print("Error While deleting attachmentFile: ")
      }
      parentView.dismiss()
    }
    
    private func deleteAttachmentFile(completion: (() -> Void)? = nil) {
      do {
        if let url = parentView.url, let oldURL = parentView.localURL {
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
  
  // MARK: - PreviewItem
  
  public class PreviewItem: NSObject, QLPreviewItem {
    public var previewItemURL: URL?
    public var previewItemTitle: String?
    
    public init(url: URL?, title: String?) {
      previewItemURL = url
      previewItemTitle = title
    }
  }
  
  // MARK: - Create a Copy
  
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
  
  // MARK: - QuickLookEditError
  
  enum QuickLookEditError: Error {
    case editIconNotFound
  }
}
