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

    func fileResult(from pdf: PDFDocument, fileURL: URL, completionHandler: (Organizer.FileResult) -> Void)

    // MARK: - Analyzing Methods

    func nameByAuthor(of pdf: PDFDocument, with fileURL: URL) -> String?
    func nameBySearchTerms(in pdf: PDFDocument, with fileURL: URL) -> String?
    func nameByVision(in pdf: PDFDocument, with fileURL: URL, completionHandler: (String?) -> Void)
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

    func nameByVision(in pdf: PDFDocument, with fileURL: URL, completionHandler: (String?) -> Void) {
        guard let firstPage = pdf.page(at: 0) else {
            completionHandler(nil)
            return
        }
        let pageRect = firstPage.bounds(for: .mediaBox)
        let image = NSImage(size: .init(width: pageRect.size.width, height: pageRect.size.height))
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            completionHandler(nil)
            return
        }
        context.saveGState()
        context.setFillColor(NSColor.white.cgColor)
        context.fill(.init(origin: .zero, size: .init(width: pageRect.size.width, height: pageRect.size.height)))

        firstPage.draw(with: .mediaBox, to: context)

        context.restoreGState()
        image.unlockFocus()
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completionHandler(nil)
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completionHandler(nil)
                return
            }

            let recognizedTexts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            print(recognizedTexts)
            completionHandler(nil)
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try? requestHandler.perform([request])
    }
}
