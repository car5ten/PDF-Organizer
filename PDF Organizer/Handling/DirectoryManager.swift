//
//  DirectoryManager.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

import Foundation

/// A singleton class responsible for thread-safe directory creation.
///
/// `DirectoryManager` ensures that directories are created safely in a concurrent environment.
/// It uses a serial dispatch queue to prevent race conditions when multiple operations attempt to create the same directory.
///
/// ## Thread Safety
/// - A private serial `DispatchQueue` (`directoryQueue`) is used to synchronize directory creation.
/// - This prevents multiple threads from attempting to create the same directory simultaneously.
///
/// ## Example Usage
///
/// ```swift
/// let directoryURL = URL(fileURLWithPath: "/Documents/Reports/2024")
/// let success = DirectoryManager.shared.createDirectorySafely(at: directoryURL)
/// print(success ? "Directory created successfully!" : "Failed to create directory.")
/// ```
///
/// If the directory already exists, it is not created again, avoiding unnecessary file system operations.
///
/// ## Behavior:
/// - If the directory **does not exist**, it is created, and `true` is returned.
/// - If the directory **already exists**, `true` is returned without modification.
/// - If an error occurs (e.g., lack of permissions), `false` is returned, and the error is logged.
///
/// ## Example Output:
/// ```
/// ✅ Directory created: /Documents/Reports/2024
/// ℹ️ Directory already exists: /Documents/Reports/2024
/// ❌ Failed to create directory at /Documents/Reports/2024: Permission denied
/// ```
///
class DirectoryManager {

    /// Singleton instance of `DirectoryManager`
    static let shared = DirectoryManager()

    /// Private serial queue for thread-safe directory creation.
    /// Ensures that multiple threads do not attempt to create the same directory simultaneously.
    private let directoryQueue = DispatchQueue(label: "dev.carsten.pdf.organizer.directoryQueue")

    /// Private initializer to enforce singleton pattern and prevent external instantiation.
    private init() {}

    /// Creates a directory safely in a thread-safe manner.
    ///
    /// - Parameter url: The URL of the directory to create.
    /// - Returns: `true` if the directory was successfully created or already exists, `false` otherwise.
    ///
    /// This function ensures that directory creation is atomic by executing synchronously
    /// within a serial queue, preventing race conditions when multiple threads attempt to create the same directory.
    func createDirectorySafely(at url: URL) -> Bool {
        directoryQueue.sync {
            do {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    print("✅ Directory created: \(url.path)")
                    return true
                } else {
                    print("ℹ️ Directory already exists: \(url.path)")
                    return true
                }
            } catch {
                print("❌ Failed to create directory at \(url.path): \(error.localizedDescription)")
                return false
            }
        }
    }
}
