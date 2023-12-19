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
  @Binding var selectedURL: URL?
  
  init(_ selectedURL: Binding<URL?>,
       manager: AttachmentManager) {
    _viewModel = StateObject(wrappedValue: .init(manager))
    _selectedURL = selectedURL
  }
  
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
  
  private var saveButton: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Save") {
        selectedURL = viewModel.fileURL
        dismiss()
      }
    }
  }
  
  private var cancelButton: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        viewModel.removeAudioFile()
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
      }
    }
  }
}

struct AudioRecorderView_Previews: PreviewProvider {
  @State static private var selectedItem: URL?
  static var previews: some View {
    AudioRecorderView($selectedItem, manager: .init(.downloads))
  }
}
