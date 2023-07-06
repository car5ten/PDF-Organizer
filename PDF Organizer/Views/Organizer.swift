//
//  Organizer.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import SwiftUI
import PDFKit
import AppKit
import Vision

class Organizer: ObservableObject {

    struct FileResult {
        let fileName: String
        let directory: URL
    }

    private var progress: Progress = .init()

    @Published var currentCount: Float = 0
    @Published var totalCount: Float = 0

    var pdfHandlers: [PDFHandler] = []
    var isWorking: Bool { currentCount != totalCount }

    func organize(_ files: [NSItemProvider]) async {
        guard files.isEmpty == false else { return }
        progress = .init(totalUnitCount: Int64(files.count))
        for file in files {
            let url: URL? = await withCheckedContinuation { continuation in
                let fileProgress = file.loadFileRepresentation(for: .pdf, openInPlace: true) { url, _, _ in
                    continuation.resume(with: .success(url))
                }
                progress.addChild(fileProgress, withPendingUnitCount: fileProgress.totalUnitCount)
            }

            guard let url,
                  let pdf = PDFDocument(url: url) else { return }
            let rootDirectory = Directory(name: url.deletingLastPathComponent().absoluteString)
            let convertedDirectory = Tree.converted(rootDirectory)
            let failedDirectory = Tree.failed(convertedDirectory)
            guard case .success = createDirectoryIfNecessary(at: failedDirectory.inversePath) else { return }

            for pdfHandler in pdfHandlers {
                guard await pdfHandler.isHandler(for: pdf) else { continue }
                if let fileResult = await pdfHandler.fileResult(from: pdf) {
                    let fileDirectory = convertedDirectory.inversePath.appending(path: fileResult.directory.path())
                    guard case .success = createDirectoryIfNecessary(at: fileDirectory) else { return }
                    let fileUrl = fileDirectory.appending(component: fileResult.fileName)
                    FileManager.default.secureCopyItem(at: url, to: fileUrl)
                } else {
                    FileManager.default.secureCopyItem(at: url, to: failedDirectory.inversePath.appending(component: url.lastPathComponent))
                }

            }
        }
        return
    }

    private func createDirectoryIfNecessary(at url: URL) -> Result<URL, Error> {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory) == false {
            do {
                try fileManager.createDirectory(atPath: url.path(),
                                                withIntermediateDirectories: true,
                                                attributes: nil)
                return .success(url)
            } catch {
                return .failure(error)
            }
        }
        return .success(url)
    }
}

private extension FileManager {

    func secureCopyItem(at srcURL: URL, to dstURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
        }
    }

}
