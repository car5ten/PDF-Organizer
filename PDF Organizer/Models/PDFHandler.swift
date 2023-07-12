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

    var uniqueIdentifier: String { get }
    var matchFirstPageOnly: Bool { get }
    var matchFullSearchTerm: Bool { get }
    var searchTerms: [String] { get }
    var author: String? { get }

    // MARK: - Result Method

    func fileResult(from pdf: PDFDocument) async -> Organizer.FileResult?

    // MARK: - Identifier Methods

    func isHandler(for pdf: PDFDocument) async -> Bool
    func matches(pdf: PDFDocument) async -> Bool

    // MARK: - Analyzing Methods

    func creationDateByAuthor(of pdf: PDFDocument) -> Date?
    func observationsFromVision(in pdf: PDFDocument) async -> [String]?
}

extension PDFHandler {

    var author: String? { nil }
    var matchFirstPageOnly: Bool { true }
    var matchFullSearchTerm: Bool { true }

    // MARK: - Identifier Methods

    func isHandler(for pdf: PDFDocument) async -> Bool {
        var isHandler = false
        if creationDateByAuthor(of: pdf) != nil {
            isHandler = true
        } else if let observations = await observationsFromVision(in: pdf) {
            isHandler = find(searchTerms: [uniqueIdentifier], in: observations, matchFullSearchTerm: true)
        }
        return isHandler
    }

    func matches(pdf: PDFDocument) async -> Bool {
        guard let observations = await observationsFromVision(in: pdf) else { return false }
        return find(searchTerms: searchTerms, in: observations, matchFullSearchTerm: matchFullSearchTerm)
    }

    // MARK: - Analyzing Methods

    func creationDateByAuthor(of pdf: PDFDocument) -> Date? {
        guard let dict = pdf.documentAttributes,
              let author = dict["Author"] as? String,
              self.author == author,
              let creationDate = dict["CreationDate"] as? Date else { return nil }
        return creationDate
    }

    func observationsFromVision(in pdf: PDFDocument) async -> [String]? {
        let pageRange = matchFirstPageOnly ? 0 ..< 1 : 0 ..< pdf.pageCount
        var observations: [String]?
        for index in pageRange {
            guard let page = pdf.page(at: index),
                  let newObservations = await observationsFromVision(of: page) else { continue }
            if observations != nil {
                observations = (observations ?? []) + newObservations
            } else {
                observations = newObservations
            }
        }
        guard let observations else { return nil }
        return Array(Set(observations))
    }

    private func find(searchTerms: [String], in observations: [String], matchFullSearchTerm: Bool) -> Bool {
        if matchFullSearchTerm {
            return Set(observations).intersection(searchTerms).isEmpty == false
        } else {
            let match = observations.first { observation in
                let match = searchTerms.first { searchTerm in
                    observation.contains(searchTerm)
                }
                return match != nil
            }
            return match != nil
        }
    }

    private func observationsFromVision(of page: PDFPage) async -> [String]? {
        let pageRect = page.bounds(for: .mediaBox)
        let image = NSImage(size: .init(width: pageRect.size.width, height: pageRect.size.height))
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else { return nil }
        context.saveGState()
        context.setFillColor(NSColor.white.cgColor)
        context.fill(.init(origin: .zero, size: .init(width: pageRect.size.width, height: pageRect.size.height)))

        page.draw(with: .mediaBox, to: context)

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
            return observations
        }
        catch {
            print(error)
            return nil
        }
    }
}
