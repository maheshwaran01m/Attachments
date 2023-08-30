//
//  AudioRecorderView.swift
//  Attachments
//
//  Created by MAHESHWARAN on 30/08/23.
//

import SwiftUI
import AVKit

struct AudioRecorderView: View {
  
  @State private var isEnabled = false
  @State private var session: AVAudioSession?
  @State private var recorder: AVAudioRecorder?
  @State private var showAlert = false
  
  @State private var audioURLs: [URL] = []
  
  var body: some View {
    VStack {
      List(audioURLs,id: \.self) { item in
        Text(item.relativeString)
      }
      recordButton
    }
    .alert(isPresented: $showAlert) {
      Alert(title: Text("Error while recording Audio"),
            message: .init("Enable the access to record audio"))
    }
  }
  
  func url(_ name: String) -> URL {
    var url = URL.documentsDirectory
    url.append(path: "Files/\(name)")
    url.appendPathExtension("m4a")
    return url
  }
  
  private var recordButton: some View {
    Button {
      do {
        if !isEnabled {
          let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                  AVNumberOfChannelsKey: 1,
               AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
          
          recorder = try .init(url: url("records"), settings: settings)
          recorder?.record()
          isEnabled.toggle()
        } else {
          recorder?.stop()
          isEnabled.toggle()
          fetchAudio()
          return
        }
      } catch {
        print("Error")
      }
    } label: {
      ZStack {
        Circle()
          .fill(.red)
          .frame(width: 70, height: 70)
        
        if isEnabled {
          Circle()
            .stroke(Color.primary, lineWidth: 6)
            .frame(width: 65, height: 65)
        }
      }
    }
    .onAppear {
      do {
        session = AVAudioSession.sharedInstance()
        try session?.setCategory(.playAndRecord)
        
        session?.requestRecordPermission { isEnabled in
          if !isEnabled {
            showAlert.toggle()
          } else {
            fetchAudio()
          }
        }
      } catch {
        print("Error while creating session")
      }
    }
  }
  
  private func fetchAudio() {
    let url = URL.documentsDirectory.appending(path: "Files")
    
    let results = try? FileManager.default.contentsOfDirectory(
      at: url, includingPropertiesForKeys: nil,
      options: .producesRelativePathURLs).filter { $0.pathExtension.contains("m4a")}
    audioURLs.removeAll()
    
    results?.forEach { audioURLs.append($0) }
  }
}

struct AudioRecorderView_Previews: PreviewProvider {
  static var previews: some View {
    AudioRecorderView()
  }
}
