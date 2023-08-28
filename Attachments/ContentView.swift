//
//  ContentView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import SwiftUI

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
    }
  }
  
  @ViewBuilder
  private var contentView: some View {
    if !viewModel.attachments.isEmpty {
      List(viewModel.attachments, id: \.privateID) { item in
        AttachmentDetailView(
          item.fileName ?? "",
          image: .init(uiImage: item.getPlaceholderImage)) {
            
          }
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
      .confirmationDialog("Choose Attachments", isPresented: $viewModel.showAttachmentDialog,
                          actions: confirmationDialogActions)
      .photosPicker(isPresented: $viewModel.showPhoto, selection: $viewModel.photoPicker,
                    matching: viewModel.allowedImageType)
      
      .photosPicker(isPresented: $viewModel.showVideo, selection: $viewModel.photoPicker,
                    matching: viewModel.allowedVideoType)
      
      .fileImporter(isPresented: $viewModel.showFiles, allowedContentTypes: viewModel.allowedFileType,
                    onCompletion: viewModel.fileAction(_:))
    }
  }
  
  @ViewBuilder
  private func confirmationDialogActions() -> some View {
    Button("Photo") {
      viewModel.showPhoto.toggle()
    }
    Button("Video") {
      viewModel.showVideo.toggle()
    }
    Button("Documents") {
      viewModel.showFiles.toggle()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
