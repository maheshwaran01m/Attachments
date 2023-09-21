//
//  AudioRecorderView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 30/08/23.
//

import SwiftUI
import AVKit

struct AudioRecorderView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel: AudioRecorderViewModel
  @Binding var selectedItem: QuickLookItem?
  
  init(_ selectedItem: Binding<QuickLookItem?>,
       manager: AttachmentManager) {
    _viewModel = StateObject(wrappedValue: .init(manager, privateID: selectedItem.wrappedValue?.id ?? UUID().uuidString))
    _selectedItem = selectedItem
  }
  
  @State private var audioURLs: [URL] = []
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        timerView
        recorderView
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black)
      .navigationTitle("Record audio")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Add File Name",
             isPresented: $viewModel.showFileNameAlert,
             actions: attachmentFileNameAction)
      .toolbar {
        saveButton
        cancelButton
      }
    }
  }
  
  private var timerView: some View {
    Text(viewModel.timerString)
      .font(.title3)
      .foregroundColor(.white)
      .frame(height: 24)
      .monospacedDigit()
      .multilineTextAlignment(.center)
  }
  
  private var recorderView: some View {
    HStack(spacing: 24) {
      recordButton
      playButtonView
    }
    .onReceive(NotificationCenter.default.publisher(
      for: UIApplication.didEnterBackgroundNotification)) { _ in
        viewModel.stopRecording()
    }
  }
  
  private var recordButton: some View {
    Button {
      viewModel.startRecordingAudio()
    } label: {
      Circle()
        .stroke(.white, lineWidth: 4)
        .frame(width: 53, height: 53)
        .overlay {
          if viewModel.isRecording {
            Rectangle()
              .fill(Color.red)
              .frame(width: 24, height: 24)
          } else {
            Circle()
              .fill(Color.red)
              .frame(width: 50, height: 50)
          }
        }
    }
    .disabled(viewModel.playRecording)
  }
  
  private var playButtonView: some View {
    Button {
      viewModel.playAudioPlayer()
    } label: {
      Image(systemName: viewModel.playRecording ? "square.fill" : "play.fill")
        .resizable()
        .frame(width: 58, height: 58)
        .foregroundColor(viewModel.isRecording ? .gray : .white)
    }
    .disabled(viewModel.isRecording)
  }
  
  
  @ViewBuilder
  private func attachmentFileNameAction() -> some View {
    TextField("Enter FileName", text: $viewModel.fileName)
    ForEach(AttachmentAlertItem.allCases) { button in
      Button(button.title) {
        viewModel.attachmentFileNameAction(for: button) { fileName in
          viewModel.clearAudioSessions()
          selectedItem = .init(url: viewModel.fileURL, fileName: fileName)
          dismiss()
        }
      }
    }
  }
  
  private var saveButton: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Save") {
        viewModel.showFileNameAlert = true
      }
    }
  }
  
  private var cancelButton: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
      }
    }
  }
}

struct AudioRecorderView_Previews: PreviewProvider {
  @State static private var selectedItem: QuickLookItem?
  static var previews: some View {
    AudioRecorderView($selectedItem, manager: .init())
  }
}
