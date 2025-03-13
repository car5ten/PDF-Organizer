//
//  DirectoryNameGenerator.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

import Foundation

/// A utility class responsible for generating structured directory names based on file attributes.
///
/// `DirectoryNameGenerator` constructs a hierarchical directory path based on the provided file URL.
/// It determines the appropriate directory structure using:
/// - The **account information** (owner and bank).
/// - The **document type** (e.g., "Kontoauszug").
/// - The **date in the filename**, adjusting it by subtracting one month.
///
/// ## Example Usage
///
/// Given a file named:
/// ```
/// NameGirokonto-2782161234-Kontoauszug-20200101.pdf
/// ```
/// The resulting directory structure would be:
/// ```
/// Owner/Bankname/2782161234/Kontoauszug/2019/
/// ```
/// And the expected new filename would be:
/// ```
/// 2019-12-2782161234.pdf
/// ```
///
/// ## Example Code
/// ```swift
/// let fileURL = URL(fileURLWithPath: "/Documents/NameGirokonto-2782161234-Kontoauszug-20200101.pdf")
/// let accounts: [Account] = [.carstenGirokonto]
/// if let directory = DirectoryNameGenerator.generate(from: fileURL, using: accounts) {
///     print("Generated Directory: \(directory)")
/// }
/// ```
///
/// ## Logic:
/// 1. Extracts the **account information** from the filename.
/// 2. Determines the **document type** (if applicable).
/// 3. Extracts the **date** from the filename and shifts it **one month back**.
/// 4. Constructs the directory path in the format:
///    ```
///    Owner/Bankname/AccountNumber/DocumentType/Year
///    ```
///
/// ## Example Outputs:
/// ```
/// Generated Directory: Carsten/ING/2782161234/Kontoauszug/2019
/// ```
///
class DirectoryNameGenerator {

    /// Generates a structured directory name based on a file's attributes.
    ///
    /// - Parameters:
    ///   - url: The file URL containing the filename with relevant metadata.
    ///   - accounts: A list of `Account` objects used to determine ownership and banking details.
    /// - Returns: A `String` representing the directory path, or `nil` if the filename does not match expected patterns.
    ///
    /// The method extracts the account name, document type, and date from the filename to construct
    /// a meaningful directory path.
    static func generate(from url: URL, using accounts: [Account]) -> String? {
        guard let accountName = accounts.matches(filename: url.lastPathComponent) else { return nil }

        var directoryName = accountName.directory

        // Append document type if found in filename
        for type in DocumentType.allCases where url.lastPathComponent.contains(type.rawValue) {
            directoryName.append(type.dic)
            break
        }

        if accountName is YearBreakdownSkippable {
            return directoryName
        }

        // Extract and adjust date by shifting back one month
        guard let date = extractDate(from: url.deletingPathExtension().lastPathComponent),
              let adjustedDate = Calendar.current.date(byAdding: .month, value: -1, to: date) else { return nil }
        let year = Calendar.current.component(.year, from: adjustedDate)

        return "\(directoryName)/\(year)"
    }

    /// Extracts a date from the filename.
    ///
    /// - Parameter filename: The name of the file (without extension).
    /// - Returns: A `Date` object if a valid date is found, otherwise `nil`.
    ///
    /// The function assumes the date is at the **end of the filename** in the format `yyyyMMdd`.
    private static func extractDate(from filename: String) -> Date? {
        guard filename.count > 8 else { return nil }
        let dateString = filename.suffix(8)  // Extract last 8 characters
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: String(dateString))
    }
}
