//
//  ContentView.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    private let fileProcessor = FileProcessor()

    @State private var isTargetted: Bool = false
    @State private var isProcessing = false  // State to control whether processing is happening

    var body: some View {
        Group {
            VStack(alignment: .center, spacing: 16) {
                Spacer()
                Image(systemName: "doc.viewfinder")
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .foregroundColor(isTargetted ? .green : .white)
                    .animation(.default, value: isTargetted)
                Text("Drop files...")
                    .font(.title)
                Spacer()
            }
            .frame(width: 150, height: 150)
        }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .onDrop(of: [.pdf], isTargeted: $isTargetted) { providers in
            processFiles(providers: providers)
            return true
        }
        .disabled(isProcessing)
    }

    // Function to process files and track progress using TaskGroup
    private func processFiles(providers: [NSItemProvider]) {
        isProcessing = true  // Disable drop area while processing

        Task {
            await withTaskGroup(of: Bool.self) { taskGroup in
                for provider in providers {
                    taskGroup.addTask {
                        await fileProcessor.processFile(provider: provider)
                    }
                }

                // Collect results from all tasks
                for await result in taskGroup {
                    print("did process: \(result)")
                }
            }

            // Re-enable drop area after all processing is done
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

extension NSItemProvider: @retroactive @unchecked Sendable {}
