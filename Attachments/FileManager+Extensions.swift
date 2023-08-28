//
//  FileManager+Extensions.swift
//  Attachments
//
//  Created by MAHESHWARAN on 28/08/23.
//

import Foundation

public extension FileManager {
  
  enum SystemDirectory {
    case documents, library, temp, downloads, cache
    
    var url: URL {
      switch self {
      case .library: return .libraryDirectory
      case .documents: return .documentsDirectory
      case .temp: return .temporaryDirectory
      case .downloads: return .downloadsDirectory
      case .cache: return .cachesDirectory
      }
    }
  }
  
  // MARK: - Write
  
  func write(_ data: Data, atURL url: URL, completion: (() -> Void)? = nil) {
    do {
      try data.write(to: url, options: [.atomic])
      completion?()
    } catch {
      print("""
            Failed to write contents for URL: \(url),
            Reason: \(error.localizedDescription)
            """)
      completion?()
    }
  }
  
  // MARK: - Fetch
  
  func fileExists(_ url: URL) -> Bool {
    fileExists(atPath: url.path())
  }
  
  func directoryExists(at url: URL) -> Bool {
    var isDir: ObjCBool = false
    _ = fileExists(atPath: url.path(), isDirectory: &isDir)
    return isDir.boolValue
  }
  
  func contents(atURL url: URL) -> [URL] {
    do {
      return try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    } catch {
      print("""
            Failed to fetch contents for URL: \(url),
            Reason: \(error.localizedDescription)
            """)
      return []
    }
  }
  
  // MARK: - Path
  
  func makePath(using pathComponent: String, directory: SystemDirectory) -> URL {
    directory.url.appending(path: pathComponent)
  }
  
  func makePath(using pathComponent: String, folder: String) -> URL {
    let url = SystemDirectory.documents.url.appending(path: folder)
    
    if !directoryExists(at: url) {
      createDirectory(atURL: url)
    }
    return url.appending(path: pathComponent)
  }
  
  // MARK: - Create
  
  func createDirectory(atPath path: String) {
    var isDir: ObjCBool = false
    
    if fileExists(atPath: path, isDirectory: &isDir) {
      do {
        if !isDir.boolValue {
          try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
      } catch {
        print("""
              Failed to create directory for Path: \(path),
              Reason: \(error.localizedDescription)
              """)
      }
    } else {
      do {
        try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("""
               Failed to create directory for Path: \(path),
              Reason: \(error.localizedDescription)
              """)
      }
    }
  }
  
  func createDirectory(atURL url: URL, withIntermediate: Bool = true) {
    do  {
      if !directoryExists(at: url) {
        try createDirectory(at: url, withIntermediateDirectories: withIntermediate, attributes: nil)
      }
    } catch {
      print("""
            Failed to create directory for URL: \(url),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  func create(named name: String, folder: String) -> URL {
    let url = makePath(using: name, folder: folder)
    guard !directoryExists(at: url) else { return url }
    createDirectory(atURL: url, withIntermediate: false)
    
    return url
  }
  
  // MARK: - Copy
  
  func copy(atPath path: String, to newPath: String) {
    do {
      try copyItem(atPath: path, toPath: newPath)
    } catch {
      print("""
            Failed to copy for Path: \(path),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  func copy(atURL url: URL, to newURL: URL) {
    do {
      try copyItem(at: url, to: newURL)
    } catch {
      print("""
            Failed to copy for URL: \(url),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  // MARK: - Move
  
  func move(atURL url: URL, to newURL: URL) {
    do {
      try moveItem(at: url, to: newURL)
    } catch {
      print("""
            Failed to move for URL: \(url),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  func move(atURL path: String, to newPath: String) {
    do {
      try moveItem(atPath: path, toPath: newPath)
    } catch {
      print("""
            Failed to move for Path: \(path),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  // MARK: - Delete
  
  func remove(atURL url: URL) {
    do {
      try removeItem(at: url)
    } catch {
      print("""
            Failed to remove at URL: \(url),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  func remove(atPath path: String) {
    do {
      try removeItem(atPath: path)
    } catch {
      print("""
            Failed to remove at Path: \(path),
            Reason: \(error.localizedDescription)
            """)
    }
  }
  
  func removeAll(at urls: [URL]) {
    urls.forEach {
      remove(atURL: $0)
    }
  }
}

