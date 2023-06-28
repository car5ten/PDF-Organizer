//
//  Directory.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.06.23.
//

import Foundation

struct Directory {
    let name: String
    let fileNameSuffix: String?
    let parents: [Directory]

    var inversePath: URL {
        parents.reduce(URL(string: name)!) { child, parent in
            return parent.inversePath.appending(path: child.path())
        }
    }

    init(name: String, fileNameSuffix: String? = nil, parents: [Directory] = []) {
        self.name = name
        self.fileNameSuffix = fileNameSuffix
        self.parents = parents
    }

    init(name: String, fileNameSuffix: String? = nil, @DirectoryBuilder _ builder: () -> [Directory]) {
        self.name = name
        self.fileNameSuffix = fileNameSuffix
        self.parents = builder()
    }
}

@resultBuilder
struct DirectoryBuilder {
    static func buildBlock(_ parents: Directory...) -> [Directory] {
        parents
    }
}

enum Tree {
    static let converted = Directory(name: "Converted")
    static let failed = Directory(name: "Failed") {
        converted
    }
}
