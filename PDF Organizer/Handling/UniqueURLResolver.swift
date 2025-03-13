//
//  UniqueURLResolver.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

import Foundation

/// A utility class responsible for ensuring unique file names when saving files.
///
/// `UniqueURLResolver` checks if a file with the given URL already exists.
/// If a conflict is detected, it appends a suffix (e.g., `"copy1"`, `"copy2"`) to create a unique filename.
///
/// This is useful when renaming or moving files to prevent accidental overwrites.
///
/// ## Example Usage:
/// Suppose you want to save a file at:
/// ```
/// /Documents/Reports/2024-01-AccountStatement.pdf
/// ```
/// But if the file already exists, it ensures uniqueness by renaming it as:
/// ```
/// /Documents/Reports/2024-01-AccountStatement.copy1.pdf
/// /Documents/Reports/2024-01-AccountStatement.copy2.pdf
/// ```
///
/// - The suffix `copy1`, `copy2`, etc., is appended before the file extension.
/// - The function keeps incrementing the counter until a unique filename is found.
///
/// ## Example Code:
/// ```swift
/// let originalURL = URL(fileURLWithPath: "/Documents/Reports/2024-01-AccountStatement.pdf")
/// let uniqueURL = UniqueURLResolver.resolve(baseUrl: originalURL)
/// print(uniqueURL.path)
/// // Output: "/Documents/Reports/2024-01-AccountStatement.copy1.pdf" (if the original exists)
/// ```
///
class UniqueURLResolver {

    /// Resolves a unique file URL by appending a numeric suffix (`copyX`) if necessary.
    ///
    /// - Parameter baseUrl: The initial file URL.
    /// - Returns: A unique `URL` where the file can be safely saved.
    static func resolve(baseUrl: URL) -> URL {
        var uniqueUrl = baseUrl
        var counter = 1
        while FileManager.default.fileExists(atPath: uniqueUrl.path) {
            uniqueUrl = baseUrl.deletingPathExtension()
                .appendingPathComponent("\(baseUrl.deletingPathExtension().lastPathComponent).copy\(counter)")
                .appendingPathExtension("pdf")
            counter += 1
        }
        return uniqueUrl
    }
}
