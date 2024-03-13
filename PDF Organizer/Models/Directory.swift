//
//  Directory.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.06.23.
//

import Foundation
import PDFKit

indirect enum Directory {
    case node(name: String, child: Directory?)

    static func node(name: String) -> Directory {
        .node(name: name, child: nil)
    }

    static func failed(at relativePath: String) -> Directory {
        .node(name: relativePath, child: .node(name: "Organized", child: .node(name: "Failed")))
    }

    func append(new child: Directory) -> Directory? {
        print(self)
        if case .node(let name, let oldChild) = self {
            if let oldChild {
                let new = oldChild.append(new: child)
                return .node(name: name, child: new)
            } else {
                return .node(name: name, child: child)
            }
        }
        return self
    }

    static func failed(for pdf: PDFDocument) -> Directory? {
        guard let url = pdf.documentURL else {
            return nil
        }
        let failed = Directory.failed(at: url.deletingLastPathComponent().absoluteString)
        return failed.append(new: .node(name: url.lastPathComponent))
    }

    private var pathName: String {
        switch self {
        case .node(let name, let child):
            var url = URL(string: name)
            if let child {
                url?.append(path: child.pathName)
            }
            return url?.absoluteString.removingPercentEncoding ?? ""
        }
    }

    var path: URL? {
        URL(string: pathName)
    }
}

class LegacyDirectory {
    let name: String
    let fileNameSuffix: String?
    weak private(set) var parent: LegacyDirectory?

    var inversePath: URL {
        parent?.inversePath.appending(path: name) ?? URL(string: name)!
    }

    init(name: String, fileNameSuffix: String? = nil, parent: LegacyDirectory? = nil) {
        self.name = name
        self.fileNameSuffix = fileNameSuffix
        self.parent = parent
    }
}

enum Tree {

    static func organized(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Organized", parent: parent)
    }

    static func converted(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Converted", parent: parent)
    }

    static func failed(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Failed", parent: parent)
    }

    static func salarySlip() -> LegacyDirectory {
        .init(name: "Gehaltsnachweise")
    }

    static func salary(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Gehalt", fileNameSuffix: "Verdienstabrechnung", parent: parent)
    }

    static func registrationCertificate(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Meldebescheinigung", fileNameSuffix: "Sozialversicherungsmeldung", parent: parent)
    }

    static func jointAccount() -> LegacyDirectory {
        .init(name: "Gemeinschaftskonto")
    }

    static func ing(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "ING", parent: parent)
    }

    static func giro(_ parent: LegacyDirectory) -> LegacyDirectory {
        .init(name: "Girokonto", parent: parent)
    }

    static func carsten() -> LegacyDirectory {
        .init(name: "Carsten")
    }
}
