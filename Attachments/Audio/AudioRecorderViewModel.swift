//
//  AudioRecorderViewModel.swift
//  Attachments
//
//  Created by MAHESHWARAN on 16/09/23.
//

import SwiftUI
import AVKit

class AudioRecorderViewModel: NSObject, ObservableObject {
  
  @Published var session: AVAudioSession?
  @Published var audioRecorder: AVAudioRecorder?
  @Published var audioPlayer: AVAudioPlayer?
  @Published var playRecording = false
  @Published var isRecording = false
  @Published var showFileNameAlert = false
  @Published var fileName = ""
  @Published var elapsedTime: TimeInterval = 0
  
  var timer: Timer?
  var fileURL: URL?
  
  let manager: AttachmentManager
  
  init(_ manager: AttachmentManager) {
    self.manager = manager
    super.init()
    configureFileURL(for: manager)
    activateAudioSession()
  }
  
  private func configureFileURL(for manger: AttachmentManager) {
    guard let url = manager.attachmentFolder(for: UUID().uuidString) else { return }
    fileURL = url.appending(path: manager.getTimeStamp).appendingPathExtension("m4a")
  }
  
  func startRecordingAudio() {
    if audioRecorder != nil {
      isRecording = false
      stopRecording()
    } else {
      isRecording = true
      startRecording()
    }
  }
  
  // MARK: - Start Recording
  
  private func startRecording() {
    guard let newAudioRecorder else { return }
    newAudioRecorder.deleteRecording()
    newAudioRecorder.record()
    startTimer()
    audioRecorder = newAudioRecorder
  }
  
  private var newAudioRecorder: AVAudioRecorder? {
    let settings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 12000,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    guard let fileURL else {
      return nil
    }
    do {
      let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
      audioRecorder.prepareToRecord()
      audioRecorder.delegate = self
      return audioRecorder
    } catch {
      print("Failed to create new AVAudioRecorder instance. Reason: \(error)")
      return nil
    }
  }
  
  // MARK: - Stop Recording
  
  func stopRecording() {
    guard audioRecorder != nil else { return }
    audioRecorder?.stop()
    audioRecorder = nil
    timer?.invalidate()
  }
  
  
  // MARK: - Create Session
  
  private func activateAudioSession() {
    guard session == nil else { return }
    do {
      self.session = AVAudioSession.sharedInstance()
      try session?.setCategory(.playAndRecord)
      session?.requestRecordPermission { isEnabled in
        if !isEnabled {
          print("Access denied for creating Audio session")
        }
      }
      try session?.setActive(true)
    } catch {
      print("Error while creating Audio session")
    }
  }
  
  // MARK: - Start Playing
  
  func playAudioPlayer() {
    if audioPlayer != nil {
      playRecording = false
      stopPlaying()
    } else {
      playRecording = true
      startPlaying()
    }
  }
  
  private func startPlaying() {
    guard let newAudioPlayer else { return }
    newAudioPlayer.play()
    // handle recorder
    audioPlayer = newAudioPlayer
  }
  
  private var newAudioPlayer: AVAudioPlayer? {
    guard let fileURL else {
      return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOf: fileURL,
                                     fileTypeHint: AVFileType.m4a.rawValue)
      player.delegate = self
      player.prepareToPlay()
      return player
    } catch {
      return nil
    }
  }
  
  // MARK: - Stop Playing
  
  func stopPlaying() {
    audioPlayer = nil
    playRecording = false
  }
}

extension AudioRecorderViewModel {
  
  private func startTimer() {
    resetTimer()
    timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
      self?.elapsedTime += timer.timeInterval
    }
  }
  
  private func resetTimer() {
    elapsedTime = 0
    timer?.invalidate()
    timer = nil
  }
  
  var timerString: String {
    let minutes = Int(elapsedTime) / 60 % 60
    let seconds = Int(elapsedTime) % 60
    let milliseconds = Int(elapsedTime * 100) % 100
    return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
  }
}

// MARK: - Clear Audio File

extension AudioRecorderViewModel {
  
  func clearAudioSessions() {
    audioRecorder?.stop()
    audioRecorder = nil
    audioPlayer?.stop()
    audioPlayer = nil
  }
  
  func removeAudioFile() {
    guard let fileURL else { return }
    clearAudioSessions()
    
    do {
      if FileManager.default.fileExists(fileURL) {
        try FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
      }
    } catch {
      print("Failed to remove audio file. Reason: \(error.localizedDescription)")
    }
  }
}

// MARK: - FileName Alert
extension AudioRecorderViewModel {
  
  func attachmentFileNameAction(for type: AttachmentAlertItem,
                                completion: @escaping (String?) -> Void) {
    switch type {
    case .save:
      if !fileName.isEmpty {
        completion(fileName)
      } else {
        DispatchQueue.main.async { [weak self] in
          self?.showFileNameAlert = true
        }
      }
    case .skip:
      completion(nil)
    }
  }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderViewModel: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                       successfully flag: Bool) {
    debugPrint("Has audio recording finished successfully? : \(flag)")
  }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderViewModel: AVAudioPlayerDelegate {
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    stopPlaying()
  }
}

