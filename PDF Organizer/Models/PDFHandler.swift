//
//  PDFHandler.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import PDFKit
import Vision

protocol PDFHandler {

    // MARK: - Properties

    var author: String? { get }
    var searchTerms: [String] { get }
    var dateRegex: Regex<Substring>? { get }
    var dateFormatter: DateFormatter? { get }

    // MARK: - Methods

    func fileResult(from pdf: PDFDocument, fileURL: URL) async -> Organizer.FileResult

    // MARK: - Analyzing Methods

    func nameByAuthor(of pdf: PDFDocument, with fileURL: URL) -> String?
    func nameBySearchTerms(in pdf: PDFDocument, with fileURL: URL) -> String?
    func nameByVision(in pdf: PDFDocument, with fileURL: URL) async -> String?
}

extension PDFHandler {

    func nameByAuthor(of pdf: PDFDocument, with fileURL: URL) -> String? {
        guard let dict = pdf.documentAttributes,
              let author = dict["Author"] as? String,
              self.author == author,
              let creationDate = dict["CreationDate"] as? Date,
              let accountNumber = try? dateRegex?.firstMatch(in: fileURL.lastPathComponent)?.output,
              let dateFormatter else { return nil }
        let dateString = dateFormatter.string(from: creationDate)
        return dateString + "_" + accountNumber + ".pdf"
    }

    func nameBySearchTerms(in pdf: PDFDocument, with fileURL: URL) -> String? {
        return nil
    }

    func nameByVision(in pdf: PDFDocument, with fileURL: URL) async -> String? {
        guard let firstPage = pdf.page(at: 0) else { return nil }
        let pageRect = firstPage.bounds(for: .mediaBox)
        let image = NSImage(size: .init(width: pageRect.size.width, height: pageRect.size.height))
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else { return nil }
        context.saveGState()
        context.setFillColor(NSColor.white.cgColor)
        context.fill(.init(origin: .zero, size: .init(width: pageRect.size.width, height: pageRect.size.height)))

        firstPage.draw(with: .mediaBox, to: context)

        context.restoreGState()
        image.unlockFocus()
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        do {
            let observations: [String] = try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let observations = request.results as? [VNRecognizedTextObservation]
                        let recognizedTexts = observations?.compactMap { observation in
                            observation.topCandidates(1).first?.string
                        } ?? []
                        continuation.resume(returning: recognizedTexts)
                    }
                }

                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try requestHandler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        catch {
            print(error)
        }
        return ""
    }
}