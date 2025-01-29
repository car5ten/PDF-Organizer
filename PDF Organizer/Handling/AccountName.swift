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

/// An enum representing predefined bank accounts.
enum AccountName: String, CaseIterable, Account {
    case Dummy

    /// The account number associated with each account.
    var accountNumber: String {
        switch self {
            case .Dummy: return "2782161234"
        }
    }

    /// Keywords used to identify the account in filenames.
    var keywords: [String] {
        switch self {
            case .Dummy: return [accountNumber, "Bankname"]
        }
    }

    /// Directory path for storing files related to this account.
    var directory: String {
        switch self {
            case .Dummy: return "Owner/Bankname/\(accountNumber)"
        }
    }
}

extension Array where Element == Account {
    /// Finds the first account whose keywords match the filename.
    /// - Parameter filename: The filename to check.
    /// - Returns: An optional `Account` if a match is found.
    func matches(filename: String) -> Account? {
        self.first { account in
            account.keywords.contains { keyword in filename.contains(keyword) }
        }
    }
}
