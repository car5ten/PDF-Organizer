//
//  Organizer.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import SwiftUI
import PDFKit

class Organizer: ObservableObject {

    fileprivate enum OrganizerError: Error {
        case fileIsNoPDF
        case setupFailed
        case noPDFHandlerFound
        case noFileResult
        case fileDirectoryCreationFailed
        case fileExists
        case invalidUrl
        case processingFailed
    }

    // TODO: handle Progress
    private var progress: Progress = .init()

    var pdfHandlers: [PDFHandler] = []
    func organize(_ files: [NSItemProvider]) async throws {
        guard files.isEmpty == false else { return }
        let firstFile = files.first!
        do {
            try await prepareDirectorStructure(from: firstFile)
        } catch {
            // TODO: show error
            print(error)
            return
        }

        for file in files {
            let pdf = try await pdf(from: file)
            do {
                let pdfHandler = try await pdfHandler(for: pdf)
                // TODO: process
            } catch {
                guard let url = pdf.documentURL, let toUrl = Directory.failed(for: pdf)?.path else {
                    throw OrganizerError.processingFailed
                }
                try? FileManager.default.secureCopyItem(at: url, to: toUrl)
            }
        }
    }

    private func createDirectoryIfNecessary(at url: URL) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: url.path(),
                                  isDirectory: &isDirectory) == false {

            try fileManager.createDirectory(atPath: url.path(),
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }

    private func pdf(from file: NSItemProvider) async throws -> PDFDocument {
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            _ = file.loadFileRepresentation(for: .pdf, openInPlace: true) { url, inPlace, error in
                guard inPlace else {
                    continuation.resume(throwing: OrganizerError.setupFailed)
                    return
                }
                guard let url = url else {
                    continuation.resume(throwing: error!)
                    return
                }
                continuation.resume(returning: url)
            }
        }
        guard let pdf = PDFDocument(url: url) else {
            throw OrganizerError.invalidUrl
        }
        return pdf
    }

    private func prepareDirectorStructure(from file: NSItemProvider) async throws {
        let pdf = try await pdf(from: file)
        guard let url = pdf.documentURL else {
            throw OrganizerError.invalidUrl
        }
        let root = Directory.failed(at: url.deletingLastPathComponent().absoluteString)

        guard let url = root.path else {
            throw OrganizerError.fileDirectoryCreationFailed
        }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: url.path(),
                                  isDirectory: &isDirectory) == false {

            try fileManager.createDirectory(atPath: url.path(),
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }

    private func pdfHandler(for pdf: PDFDocument) async throws -> PDFHandler {
        for pdfHandler in pdfHandlers {
            guard await pdfHandler.isHandler(for: pdf) else { continue }
            return pdfHandler
        }
        throw OrganizerError.noPDFHandlerFound
    }

    private func process(_ setupResult: SetupResult, with pdfHandler: PDFHandler) async throws {
        guard let fileResult = await pdfHandler.fileResult(from: setupResult.pdf) else { throw OrganizerError.noFileResult }
        let fileDirectory = setupResult.convertedDirectory.inversePath.appending(path: fileResult.directory.path())
        let fileUrl: URL
        do {
            try createDirectoryIfNecessary(at: fileDirectory)
            fileUrl = fileDirectory.appending(component: fileResult.fileName)
        } catch {
            throw OrganizerError.fileDirectoryCreationFailed
        }
        guard let pdfUrl = setupResult.pdf.documentURL else { throw OrganizerError.invalidUrl }
        try FileManager.default.secureCopyItem(at: pdfUrl, to: fileUrl)
    }
}

private extension FileManager {

    func secureCopyItem(at srcURL: URL, to dstURL: URL) throws {
        guard FileManager.default.fileExists(atPath: dstURL.path) == false else {
            throw Organizer.OrganizerError.fileExists
        }
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    }

}
