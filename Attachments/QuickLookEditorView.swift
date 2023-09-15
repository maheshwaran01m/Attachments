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
  @Binding var selectedItem: QuickLookItem?
  @State private var isDiscardAlertPresented = false
  @State private var showFileNameAlert = false
  
  private let url: URL?
  private var localURL: URL?
  private let preview = QLPreviewController()
  
  public init(url: URL?, selectedItem: Binding<QuickLookItem?>) {
    self.url = url
    _selectedItem = selectedItem
    self.localURL = createCopyOfFile(url)
  }
  
  public func makeUIViewController(context: Context) -> UIViewController {
    preview.dataSource = context.coordinator
    preview.delegate = context.coordinator
    preview.currentPreviewItemIndex = 0
    preview.navigationItem.leftBarButtonItem = context.coordinator.cancelButton
    preview.navigationItem.rightBarButtonItems = [context.coordinator.saveButton,
                                                  context.coordinator.clearButton]
    return UINavigationController(rootViewController: preview)
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if isDiscardAlertPresented {
      context.coordinator.showPopupForDiscardAlert(vc: uiViewController)
    }
    if showFileNameAlert {
      context.coordinator.showPopupForFileNameAlert(vc: uiViewController)
    }
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  public class Coordinator: NSObject, QLPreviewControllerDataSource,
                            QLPreviewControllerDelegate, UITextFieldDelegate {
    
    var parent: QuickLookEditorView
    
    public init(_ parent: QuickLookEditorView) {
      self.parent = parent
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      PreviewItem(url: parent.localURL, title: parent.localURL?.lastPathComponent ?? "")
    }
    
    // MARK: - QLPreviewControllerDelegate
    
    public func previewController(_ controller: QLPreviewController,
                                  editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
      .updateContents
    }
    
    public func previewController(_ controller: QLPreviewController,
                                  didSaveEditedCopyOf previewItem: QLPreviewItem,
                                  at modifiedContentsURL: URL) {
      parent.localURL = modifiedContentsURL
    }
    
    // MARK: - NavigationItem
    
    lazy var cancelButton: UIBarButtonItem = {
      .init(image: UIImage(systemName: "chevron.backward"),
            style: .plain, target: self, action: #selector(showDiscardAlert))
    }()
    
    lazy var saveButton: UIBarButtonItem = {
      .init(title: "Save", style: .plain, target: self,
            action: #selector(showFileNameAlert))
    }()
    
    lazy var clearButton: UIBarButtonItem = {
      .init(title: "Clear", style: .plain, target: self,
            action: #selector(clearButtonClicked))
    }()
    
    @objc private func showDiscardAlert() {
      parent.isDiscardAlertPresented = true
    }
    
    @objc private func showFileNameAlert() {
      parent.showFileNameAlert = true
    }
    
    @objc private func clearButtonClicked() {
      parent.localURL = parent.createCopyOfFile(parent.url)
      parent.preview.reloadData()
    }
    
    private func addAttachmentItem(for fileName: String? = nil) {
      deleteAttachmentFile { [weak self] in
        self?.parent.dismiss()
        self?.parent.selectedItem = .init(url: self?.parent.url, fileName: fileName)
      }
    }
    
    // MARK: - File Name Alert
    
    public func showPopupForFileNameAlert(vc: UIViewController) {
      let alert = UIAlertController(title: "Add file Name",
                                    message: nil, preferredStyle: .alert)
      
      var fileNameTextField: UITextField?
      
      alert.addTextField { (textField: UITextField) in
        textField.delegate = self
        textField.placeholder = "Enter File Name"
        fileNameTextField = textField
      }
      
      let presentAlert = { [weak self] in
        vc.present(alert, animated: true) {
          self?.parent.showFileNameAlert = false
          fileNameTextField?.becomeFirstResponder()
          fileNameTextField?.selectAll(self)
        }
      }
      
      let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
        if let fileName = fileNameTextField?.text, !fileName.isEmpty {
          self?.addAttachmentItem(for: fileName)
        } else {
          alert.dismiss(animated: true) {
            presentAlert()
          }
        }
      }
      
      let skipAction = UIAlertAction(title: "Skip", style: .default) { [weak self] _ in
        self?.addAttachmentItem()
      }
      let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
        alert.dismiss(animated: true)
      }
      
      alert.addAction(saveAction)
      alert.addAction(skipAction)
      alert.addAction(cancelAction)
      alert.preferredAction = saveAction
      presentAlert()
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
      // Note: Need to restrict no of characters for attachment fileName to the limit configured
      let newText = ((textField.text ?? "") as NSString).replacingCharacters(in: range,with: string)
      return newText.count <= 250
    }
    
    // MARK: - Discard Alert
    
    public func showPopupForDiscardAlert(vc: UIViewController) {
      let message = "Attachment File will be discarded. Do you wish to proceed?"
      let alert = UIAlertController(
        title: "Warning", message: message, preferredStyle: .alert)
      
      let saveAction = UIAlertAction(title: "Proceed",
                                     style: .destructive) { [weak self] _ in
        
        alert.dismiss(animated: true) { [weak self] in
          self?.deleteAttachmentFolder()
        }
      }
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
        alert.dismiss(animated: true)
      }
      alert.addAction(cancelAction)
      alert.addAction(saveAction)
      alert.preferredAction = saveAction
      
      vc.present(alert, animated: true) { [weak self] in
        self?.parent.isDiscardAlertPresented = false
      }
    }
    
    private func deleteAttachmentFolder() {
      do {
        if let url = parent.url {
          try FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
      } catch {
        print("Error While deleting attachmentFile: ")
      }
      parent.dismiss()
    }
    
    private func deleteAttachmentFile(completion: @escaping () -> Void) {
      do {
        if let url = parent.url, let oldURL = parent.localURL {
          let newPath = oldURL.path().replacingOccurrences(of: "Copy", with: "")
          
          if FileManager.default.fileExists(atPath: newPath) {
            try FileManager.default.removeItem(at: url)
            // Replace original image with edited version of image
            try FileManager.default.moveItem(atPath: oldURL.path(), toPath: newPath)
          }
          completion()
        }
      } catch {
        print("Error While deleting attachmentFile: ")
        completion()
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
}

// MARK: - QuickLookItem

public struct QuickLookItem: Identifiable {
  public var id: String { UUID().uuidString }
  
  public var url: URL?
  public var fileName: String?
  
  public init(url: URL?, fileName: String?) {
    self.url = url
    self.fileName = fileName
  }
}

