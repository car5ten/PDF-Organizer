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

    @State private var isTargeted: Bool = false
    @State private var isProcessing = false  // State to control whether processing is happening
    @State private var completedTasks = 0    // Number of completed tasks
    @State private var failedTasks = 0       // Number of failed tasks
    @State private var totalTasks = 0        // Total number of tasks (files to process)

    var progress: Double {
        guard isProcessing else {
            return 0
        }
        // Calculating progress as a fraction of completed tasks vs total tasks
        return Double(completedTasks) / Double(totalTasks)
    }

    var failedProgress: Double {
        guard isProcessing else {
            return 0
        }
        // Calculating failed task progress as a fraction
        return Double(failedTasks) / Double(totalTasks)
    }

    var body: some View {
        Group {
            ZStack {
                    CircularProgressView(progress: progress, failedProgress: failedProgress)
                        .padding(50)
                        .foregroundColor(isTargeted ? .blue : .white.opacity(0.3))
                        .animation(.default, value: isTargeted)

                VStack(alignment: .center, spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.viewfinder")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .foregroundColor(isTargeted ? .blue : .white)
                        .animation(.default, value: isTargeted)
                    Text(isProcessing ? "Processing..." : "Drop files...")
                        .font(.title)
                    Spacer()
                }
                .frame(width: 150, height: 150)
            }
        }
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .onDrop(of: [.pdf], isTargeted: $isTargeted) { providers in
            processFiles(providers: providers)
            return true
        }
        .disabled(isProcessing)
    }

    private func processFiles(providers: [NSItemProvider]) {
        totalTasks = providers.count  // Set the total tasks for progress calculation
        completedTasks = 0            // Reset completed tasks count
        failedTasks = 0               // Reset failed tasks count

        isProcessing = true  // Disable drop area while processing

        Task {
            await withTaskGroup(of: Void.self) { taskGroup in  // Explicitly return Void
                for provider in providers {
                    taskGroup.addTask {
                        let result = await fileProcessor.processFile(provider: provider)
                        DispatchQueue.main.async {
                            if result {
                                completedTasks += 1
                            } else {
                                failedTasks += 1
                            }
                        }
                    }
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

// Circular Progress View
struct CircularProgressView: View {
    var progress: Double // Progress of completed tasks (between 0 and 1)
    var failedProgress: Double // Progress of failed tasks (between 0 and 1)

    var body: some View {
        ZStack {
            // Background circle (unfilled part of the ring)
            Circle()
                .stroke(lineWidth: 10)

            // Foreground circle (progress part of the ring)
            Circle()
                .trim(from: 0, to: progress) // Trim to show the progress
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(-90)) // Start at the top of the ring
                .animation(.easeInOut, value: progress)

            // Foreground circle (failed progress part of the ring)
            Circle()
                .trim(from: 1 - failedProgress, to: 1) // Trim to show the failed tasks
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(.red)
                .rotationEffect(.degrees(-90)) // Start at the top of the ring
                .animation(.easeInOut, value: failedProgress)
        }
        .frame(width: 200, height: 200) // Size of the ring
    }
}

#Preview(body: {
    ContentView()
})
