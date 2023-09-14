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

    fileprivate enum OrganizerError: Error {
        case fileIsNoPDF
        case setupFailed
        case noPDFHandlerFound
        case noFileResult
        case fileDirectoryCreationFailed
        case fileExists
        case invalidUrl

    }

    // TODO: handle Progress
    private var progress: Progress = .init()

    var pdfHandlers: [PDFHandler] = []

    func organize(_ files: [NSItemProvider]) async {
        guard files.isEmpty == false else { return }
        for file in files {
            let setupResult: SetupResult
            do {
                setupResult = try await prepareDirectorStructure(for: file)
            } catch {
                // setup failed
                print(error)
                return
            }
            do {
                let pdfHandler = try await pdfHandler(for: setupResult.pdf)
                try await process(setupResult, with: pdfHandler)
            } catch {
                guard let url = setupResult.pdf.documentURL else { return }
                try? FileManager.default.secureCopyItem(at: url, to: setupResult.failedDirectory.inversePath.appending(component: url.lastPathComponent))
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

    private func prepareDirectorStructure(for file: NSItemProvider) async throws -> SetupResult {
        let url: URL? = await withCheckedContinuation { continuation in
            _ = file.loadFileRepresentation(for: .pdf, openInPlace: true) { url, _, _ in
                continuation.resume(with: .success(url))
            }
        }

        // create PDFDocument
        guard let url,
              let pdf = PDFDocument(url: url) else { throw OrganizerError.fileIsNoPDF }

        // setup Directories
        let rootDirectory = Directory(name: url.deletingLastPathComponent().absoluteString)
        let organizedDirectory = Tree.organized(rootDirectory)
        let convertedDirectory = Tree.converted(organizedDirectory)
        let failedDirectory = Tree.failed(organizedDirectory)
        do {
            try createDirectoryIfNecessary(at: failedDirectory.inversePath)
        } catch {
            throw OrganizerError.setupFailed
        }
        return SetupResult(rootDirectory: rootDirectory,
                           organizedDirecty: organizedDirectory,
                           convertedDirectory: convertedDirectory,
                           failedDirectory: failedDirectory,
                           pdf: pdf)
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
