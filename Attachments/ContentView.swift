//
//  ContentView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import SwiftUI
import QuickLook
import Toast

struct ContentView: View {
  
  @StateObject private var viewModel = AttachmentViewModel()
  
  var body: some View {
    mainView
  }
  
  private var mainView: some View {
    NavigationStack {
      contentView
        .toolbar(content: addButton)
        .navigationTitle("Files")
        .showToast($viewModel.showToast)
    }
  }
  
  @ViewBuilder
  private var contentView: some View {
    if !viewModel.attachments.isEmpty {
      List($viewModel.attachments, id: \.privateID) { item in
        AttachmentDetailView(
          item.wrappedValue.fileName ?? "",
          imageStyle: item.wrappedValue.getThumbImage) {
            viewModel.delete(item.wrappedValue.privateID)
          }
          .onTapGesture {
            viewModel.quickLookURL = URL(filePath: item.wrappedValue.localFilePath)
          }
          .quickLookPreview($viewModel.quickLookURL, in: viewModel.attachmentURLs)
          .listRowSeparator(.hidden)
          .padding(.horizontal, 8)
          .listRowBackground(
            Color.secondary.opacity(0.1)
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .padding([.vertical, .horizontal], 4)
          )
      }
      .listStyle(.plain)
    } else {
      ZStack {
        Color.gray.opacity(0.1)
        VStack {
          iconView
          titleView
        }
      }
      .ignoresSafeArea(.container, edges: .bottom)
    }
  }
  
  @ViewBuilder
  private var titleView: some View {
    Text("No Attachments")
      .multilineTextAlignment(.center)
      .foregroundStyle(Color.secondary)
  }
  
  private var iconView: some View {
    Image(systemName: "square.on.square.badge.person.crop")
      .font(.title)
      .foregroundStyle(Color.secondary)
      .frame(minWidth: 20, minHeight: 20)
  }
  
  private func addButton() -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        viewModel.showAttachmentDialog.toggle()
      } label: {
        Image(systemName: "plus")
      }
      .confirmationDialog("Choose Attachments", isPresented: $viewModel.showAttachmentDialog, titleVisibility: .visible, actions: confirmationDialogActions)
      
      .photosPicker(isPresented: $viewModel.showPhoto, selection: $viewModel.photoPicker,
                    matching: viewModel.allowedImageType)
      
      .fileImporter(isPresented: $viewModel.showFiles, allowedContentTypes: viewModel.allowedFileType, onCompletion: viewModel.fileAction(_:))
      
      .fullScreenCover(isPresented: $viewModel.showCamera) {
        ImagePickerView(viewModel.sourceType, selectedImage: $viewModel.selectedImage,
                        selectedURL: $viewModel.selectedVideo)
        .ignoresSafeArea()
      }
      .alert("Settings", isPresented: $viewModel.showCameraAlert) {
        Button("Cancel", action: {})
        if let url = URL(string: UIApplication.openSettingsURLString) {
          Link("Open", destination: url)
        }
      } message: {
        Text("Would you like to open settings")
      }
      .sheet(isPresented: $viewModel.showAudio) {
        AudioRecorderView($viewModel.audioAttachmentItem,
                          manager: viewModel.attachmentManager)
          .presentationDetents([.medium])
      }
      .sheet(isPresented: $viewModel.quickLookEdit) {
        if let path = viewModel.selectedAttachmentItem?.localFilePath, !path.isEmpty {
          QuickLookEditorView(isPresented: $viewModel.quickLookEdit, url: .init(filePath: path),
                              selectedURL: $viewModel.selectedQuickLookItem)
        }
      }
      .alert("Add File Name",
             isPresented: $viewModel.showFileNameAlert,
             actions: attachmentFileNameAction)
    }
  }
  
  @ViewBuilder
  private func confirmationDialogActions() -> some View {
    Button("Take Photo") {
      viewModel.sourceType = .takePhoto
      viewModel.checkAccessForImagePicker()
    }
    Button("Take Video") {
      viewModel.sourceType = .takeVideo
      viewModel.checkAccessForImagePicker()
    }
    Button("Photo Library") {
      viewModel.showPhoto.toggle()
    }
    
    Button("Audio") {
      viewModel.showAudio.toggle()
    }
    
    Button("Documents") {
      viewModel.showFiles.toggle()
    }
  }
  
  @ViewBuilder
  private func attachmentFileNameAction() -> some View {
    TextField("Enter FileName", text: $viewModel.fileName)
    ForEach(AttachmentAlertItem.allCases) { button in
      Button(button.title) {
        viewModel.attachmentFileNameAction(for: button)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
