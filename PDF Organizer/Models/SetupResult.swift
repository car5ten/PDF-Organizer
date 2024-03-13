//
//  SetupResult.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 14.09.23.
//

import Foundation
import PDFKit

struct SetupResult {

    private let rootDirectory: LegacyDirectory
    private let organizedDirecty: LegacyDirectory
    let convertedDirectory: LegacyDirectory
    let failedDirectory: LegacyDirectory
    let pdf: PDFDocument

    init(rootDirectory: LegacyDirectory,
         organizedDirecty: LegacyDirectory,
         convertedDirectory: LegacyDirectory,
         failedDirectory: LegacyDirectory,
         pdf: PDFDocument) {
        self.rootDirectory = rootDirectory
        self.organizedDirecty = organizedDirecty
        self.convertedDirectory = convertedDirectory
        self.failedDirectory = failedDirectory
        self.pdf = pdf
    }
}
