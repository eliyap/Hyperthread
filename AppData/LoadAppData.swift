//
//  LoadAppData.swift
//  Hyperthread
//
//  Source:
//  https://www.codementor.io/@paulzabelin/xcode-app-data-suni6p4ma
//

import Foundation

func loadAppData() {
    let fm = Foundation.FileManager.default
    
    guard
        let contentsURL = Bundle.main.url(forResource: "ReloadTests", withExtension: "xcappdata")?.appendingPathComponent("AppData"),
        let destinationRoot = fm.urls(for: .libraryDirectory, in: .userDomainMask).last?.deletingLastPathComponent(),
        let enumerator = fm.enumerator(at: contentsURL, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: nil)
    else {
        return
    }

    while let sourceURL = enumerator.nextObject() as? URL {
        guard
            let resourceValues = try? sourceURL.resourceValues(forKeys: [.isDirectoryKey]),
            let isDirectory = resourceValues.isDirectory,
            !isDirectory
        else { continue }

        let path = sourceURL.standardizedFileURL.path.replacingOccurrences(of: contentsURL.standardizedFileURL.path, with: "")
        let destinationURL = destinationRoot.appendingPathComponent(path)

        do {
            try fm.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            if fm.fileExists(atPath: destinationURL.path) {
                try fm.removeItem(at: destinationURL)
            }
            try fm.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            Swift.debugPrint("Failed to copy \(sourceURL)")
        }
    }
}
