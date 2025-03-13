//
//  Dummy.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 13.03.25.
//


struct Dummy: Account {
    var accountNumber: String { "2782161234" }
    var keywords: [String] { ["Bankname", accountNumber] }
    var directory: String { "Owner/Bankname/\(accountNumber)" }
}