//
//  AttachmentsApp.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import SwiftUI

@main
struct AttachmentsApp: App {
  var body: some Scene {
    WindowGroup {
      let _ = print("Path: \(URL.documentsDirectory.path())")
      ContentView()
    }
  }
}
