//
//  FileProcessor.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 28.01.25.
//

import Foundation
import UniformTypeIdentifiers

class FileProcessor {

    private let directoryManager: DirectoryManager

    init(directoryManager: DirectoryManager = .shared) {
        self.directoryManager = directoryManager
    }

    /// Processes a dropped PDF file by renaming it and organizing it into a structured directory.
    ///
    /// This function extracts information from the filename, determines the appropriate storage location,
    /// renames the file according to predefined rules, and ensures safe directory creation.
    ///
    /// ### Example:
    /// Given a dropped file:
    /// ```
    /// NameGirokonto-2782161234-Kontoauszug-20200101.pdf
    /// ```
    /// The file is processed into the following directory structure:
    ///
    /// ```
    /// Owner/Bankname/2782161234/Kontoauszug/2019/2019-12-2782161234.pdf
    /// ```
    ///
    /// **Processing Steps:**
    /// 1. Extracts the hardcoded **AccountName.dic** from the **Document Type**.
    /// 2. Determines the **storage directory**:
    ///    - `Owner/Bankname/2782161234/Kontoauszug`
    ///    - Uses the **year** extracted from the filename and adjusts to the **previous month**.
    /// 3. Renames the file to match the following format:
    ///    - `YYYY-MM-AccountNumber.pdf`
    ///    - For example, `2020-01-01` → Adjusts to `2019-12`, resulting in:
    ///      ```
    ///      2019-12-2782161234.pdf
    ///      ```
    /// 4. Ensures the **directory exists** before moving the file.
    /// 5. If a file with the same name already exists, appends `".copy"`, e.g.:
    ///    ```
    ///    2019-12-2782161234.copy.pdf
    ///    ```
    ///
    /// - Parameter provider: The `NSItemProvider` containing the dropped PDF file.
    /// - Returns: `true` if processing is successful, `false` otherwise.
    func processFile(provider: NSItemProvider) async -> Bool {
        let accounts: [Account] = Accounts.all
        guard provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier),
              let itemUrl = try? await provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) as? URL else { return false }

        do {
            // Step 1: Extract directory name
            guard let directoryName = DirectoryNameGenerator.generate(from: itemUrl, using: accounts) else { return false }

            // Step 2: Create the directory
            let targetDirectory = itemUrl.deletingLastPathComponent().appendingPathComponent(directoryName)
            guard directoryManager.createDirectorySafely(at: targetDirectory) else { return false }

            // Step 3: Rename the file
            guard let newFilename = FilenameGenerator.generate(from: itemUrl.deletingPathExtension().lastPathComponent, using: accounts) else { return false }


            // Step 4: Resolve unique URL
            let newUrl = UniqueURLResolver.resolve(baseUrl: targetDirectory.appendingPathComponent(newFilename).appendingPathExtension(for: .pdf))

            // Step 5: Move the file
            try FileManager.default.moveItem(at: itemUrl, to: newUrl)
            return true
        } catch {
            return false
        }
    }
}
