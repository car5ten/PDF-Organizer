//
//  Directory.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.06.23.
//

import Foundation

class Directory {
    let name: String
    let fileNameSuffix: String?
    weak private(set) var parent: Directory?

    var inversePath: URL {
        parent?.inversePath.appending(path: name) ?? URL(string: name)!
    }

    init(name: String, fileNameSuffix: String? = nil, parent: Directory? = nil) {
        self.name = name
        self.fileNameSuffix = fileNameSuffix
        self.parent = parent
    }
}

enum Tree {

    static func organized(_ parent: Directory) -> Directory {
        .init(name: "Organized", parent: parent)
    }

    static func converted(_ parent: Directory) -> Directory {
        .init(name: "Converted", parent: parent)
    }

    static func failed(_ parent: Directory) -> Directory {
        .init(name: "Failed", parent: parent)
    }
}
