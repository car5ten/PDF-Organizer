//
//  AccountName.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

/// A protocol defining an account, including its number, associated keywords, and directory structure.
protocol Account {
    var accountNumber: String { get }
    var keywords: [String] { get }
    var directory: String { get }
}

protocol Suffixable {
    var suffix: String { get }
}

struct Dummy: Account {
    var accountNumber: String { "2782161234" }
    var keywords: [String] { ["Bankname", accountNumber] }
    var directory: String { "Owner/Bankname/\(accountNumber)" }
}

enum Accounts {
    static let all: [Account] = [
        Dummy()
    ]
}

extension Array where Element == Account {
    /// Finds the first account whose keywords match the filename.
    /// - Parameter filename: The filename to check.
    /// - Returns: An optional `Account` if a match is found.
    func matches(filename: String) -> Account? {
        self.first { account in
            account.keywords.allSatisfy { keyword in filename.contains(keyword) }
        }
    }
}
