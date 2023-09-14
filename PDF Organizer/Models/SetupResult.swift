//
//  SetupResult.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 14.09.23.
//

import Foundation
import PDFKit

struct SetupResult {

    private let rootDirectory: Directory
    private let organizedDirecty: Directory
    let convertedDirectory: Directory
    let failedDirectory: Directory
    let pdf: PDFDocument

    init(rootDirectory: Directory,
         organizedDirecty: Directory,
         convertedDirectory: Directory,
         failedDirectory: Directory,
         pdf: PDFDocument) {
        self.rootDirectory = rootDirectory
        self.organizedDirecty = organizedDirecty
        self.convertedDirectory = convertedDirectory
        self.failedDirectory = failedDirectory
        self.pdf = pdf
    }
}
