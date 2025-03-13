//
//  FilenameGenerator.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

import Foundation

/// A utility class responsible for generating structured filenames based on predefined rules.
///
/// `FilenameGenerator` constructs a new filename by extracting the account information and date from the original filename.
/// The date is **shifted back one month** before formatting the new filename.
///
/// ## Example Usage
///
/// Given an original filename:
/// ```
/// NameGirokonto-2782161234-Kontoauszug-20200101.pdf
/// ```
/// The generated new filename would be:
/// ```
/// 2019-12-2782161234.pdf
/// ```
///
/// ## Example Code
/// ```swift
/// let originalFilename = "NameGirokonto-2782161234-Kontoauszug-20200101"
/// let accounts: [Account] = [.carstenGirokonto]
/// if let newFilename = FilenameGenerator.generate(from: originalFilename, using: accounts) {
///     print("Generated Filename: \(newFilename)")
/// }
/// ```
///
/// ## Logic:
/// 1. Extracts the **account information** from the filename.
/// 2. Extracts the **date** (assumed to be the last 8 digits in `yyyyMMdd` format).
/// 3. **Shifts the date back by one month**.
/// 4. Constructs the filename in the format:
///    ```
///    yyyy-MM-accountNumber
///    ```
///
/// ## Example Outputs:
/// ```
/// Generated Filename: 2019-12-2782161234
/// ```
class FilenameGenerator {

    /// Generates a structured filename based on the original file name.
    ///
    /// - Parameters:
    ///   - original: The original filename without the file extension.
    ///   - accounts: A list of `Account` objects used to determine ownership and banking details.
    /// - Returns: A `String` representing the new filename, or `nil` if the filename does not match expected patterns.
    ///
    /// The method extracts the account name and date from the filename, shifts the date back by **one month**,
    /// and formats the filename as `yyyy-MM-accountNumber`.
    static func generate(from original: String, using accounts: [Account]) -> String? {
        guard let accountName = accounts.matches(filename: original),
              let date = extractDate(from: original),
              let adjustedDate = Calendar.current.date(byAdding: .month, value: -1, to: date) else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        if let suffixable = accountName as? Suffixable {
            return "\(dateFormatter.string(from: adjustedDate))-\(accountName.accountNumber)-\(suffixable.suffix)"
        } else {
            return "\(dateFormatter.string(from: adjustedDate))-\(accountName.accountNumber)"
        }
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
