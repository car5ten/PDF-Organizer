//
//  PDF.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

enum PDF: CaseIterable, RawRepresentable {

    // MARK: - Computed Properties

    var author: String? {
        switch self {
        @unknown default:
            return nil
        }
    }

    var searchTerms: [String] {
        switch self {
        @unknown default:
            return []
        }
    }

    var dateRegex: Regex<Substring>? {
        switch self {
        @unknown default:
            return nil
        }
    }

    // MARK: - Cases

    // case

    // MARK: - RawRepresentable

    var rawValue: String {
        author!
    }

    init?(rawValue: String) {
        guard let match = Self.allCases.first(where: { pdf in
            pdf.author == rawValue
        }) else { return nil }
        self = match
    }
}
