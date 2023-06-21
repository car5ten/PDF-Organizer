//
//  Organizer.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import SwiftUI
import PDFKit

class Organizer: ObservableObject {

    private enum Constants {
        static let targetDirectoryName = "Converted"
    }

    private var progress: Progress = .init()

    @Published var currentCount: Float = 0
    @Published var totalCount: Float = 0

    var isWorking: Bool { currentCount != totalCount }

    func organize(_ files: [NSItemProvider]) -> Bool {
        guard files.isEmpty == false else { return false }
        progress = .init(totalUnitCount: Int64(files.count))
        for file in Array(repeating: files.first!, count: 100) {
            let fileProgress = file.loadFileRepresentation(for: .pdf, openInPlace: true) { url, _, _ in
                guard let url,
                      let pdf = PDFDocument(url: url) else { return }

                let fileName = url.lastPathComponent
                var newFileName: String?
                if let authorName = self.nameByAuthor(of: pdf, with: fileName) {
                    newFileName = authorName
                } else if let searchTermName = self.nameBySearchTerms(in: pdf, with: fileName) {
                    newFileName = searchTermName
                } else if let visionName = self.nameByVision(in: pdf, with: fileName) {
                    newFileName = visionName
                }

                guard let newFileName,
                      case .success(let targetUrl) = self.createDirectoryIfNecessary(at: url) else { return }

                let copyPath = targetUrl.appending(component: newFileName)
                FileManager.default.secureCopyItem(at: url, to: copyPath)
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

    private func nameByAuthor(of pdf: PDFDocument, with fileName: String) -> String? {
        guard let dict = pdf.documentAttributes,
              let author = dict["Author"] as? String,
              let author = PDF(rawValue: author),
              let creationDate = dict["CreationDate"] as? Date,
              let dateRegex = author.dateRegex,
              let accountNumber = try? dateRegex.firstMatch(in: fileName)?.output else { return nil }
        let dateString = formatter.string(from: creationDate)
        return dateString + "_" + accountNumber + ".pdf"
    }

    private func nameBySearchTerms(in pdf: PDFDocument, with fileName: String) -> String? {
        // TODO
        return nil
    }

    private func nameByVision(in pdf: PDFDocument, with fileName: String) -> String? {
        // TODO
        return nil
    }

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM"
        return formatter
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
