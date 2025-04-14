//
//  DateRepresentable.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 14.04.25.
//

import Foundation

protocol DateRepresentable {
    var dateFormat: String { get }
}

extension DateRepresentable {
    var dateFormat: String {
        "yyyy-MM"
    }
}
