//
//  AccountingType.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

/// Represents different document types and their corresponding directory structure.
enum DocumentType: String, CaseIterable {
    case Kontoauszug
    case Sonstiges

    /// Directory path segment for each document type.
    var dic: String {
        switch self {
            case .Kontoauszug: return "/Kontoauszug"
            case .Sonstiges: return "/Sonstiges"
        }
    }
}
