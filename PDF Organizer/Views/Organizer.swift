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

    private enum Constants {
        static let targetDirectoryName = "Converted"
    }

    private var progress: Progress = .init()

    @Published var currentCount: Float = 0
    @Published var totalCount: Float = 0

    var pdfHandlers: [PDFHandler] = []
    var isWorking: Bool { currentCount != totalCount }

    func organize(_ files: [NSItemProvider]) -> Bool {
        guard files.isEmpty == false else { return false }
        progress = .init(totalUnitCount: Int64(files.count))
        for file in files {
            let fileProgress = file.loadFileRepresentation(for: .pdf, openInPlace: true) { url, _, _ in
                guard let url,
                      let pdf = PDFDocument(url: url) else { return }
                for pdfHandler in self.pdfHandlers {
                    let fileResult = pdfHandler.fileResult(from: pdf, fileURL: url)
                    print(fileResult)
                }
//                let fileName = url.lastPathComponent
//                var newFileName: String?
//                if pdf.string?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
//                    newFileName = self.nameByVision(in: pdf, with: fileName)
//                } else if let authorName = self.nameByAuthor(of: pdf, with: fileName) {
//                    newFileName = authorName
//                } else if let searchTermName = self.nameBySearchTerms(in: pdf, with: fileName) {
//                    newFileName = searchTermName
//                } else {
//                    newFileName = "NOT_CONVERTED"
//                }

//                guard let newFileName,
//                      case .success(let targetUrl) = self.createDirectoryIfNecessary(at: url) else { return }
//
//                let copyPath = targetUrl.appending(component: newFileName)
//                FileManager.default.secureCopyItem(at: url, to: copyPath)
            }
            progress.addChild(fileProgress, withPendingUnitCount: fileProgress.totalUnitCount)
        }
        return true
    }

    private func createDirectoryIfNecessary(at url: URL) -> Result<URL, Error> {
        let fileManager = FileManager.default
        let targetUrl = url
            .deletingLastPathComponent()
            .appending(path: Constants.targetDirectoryName)
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: targetUrl.path(), isDirectory: &isDirectory) == false {
            do {
                try fileManager.createDirectory(atPath: targetUrl.path(),
                                                withIntermediateDirectories: true,
                                                attributes: nil)
                return .success(targetUrl)
            } catch {
                return .failure(error)
            }
        }
        return .success(targetUrl)
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
