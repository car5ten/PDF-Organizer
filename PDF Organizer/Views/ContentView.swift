//
//  ContentView.swift
//  PDF Organizer
//
//  Created by Carsten Voß on 21.06.23.
//

import SwiftUI

struct ContentView: View {

    private enum Constants {
        static var doubleFormat: FloatingPointFormatStyle<Double> {
            .number.precision(.fractionLength(0))
        }
    }

    @EnvironmentObject var organizer: Organizer
    @State private var isTargetted: Bool = false

    var body: some View {
        Group {
            VStack(alignment: .center, spacing: 16) {

                Spacer()
                if organizer.isWorking {
                    ProgressView(value: organizer.currentCount,
                                 total: organizer.totalCount)
                    .progressViewStyle(.circular)
                    .tint(.green)
                    .frame(width: 50, height: 50, alignment: .center)
                    Text("\(organizer.currentCount.formatted(Constants.doubleFormat)) / \(organizer.totalCount.formatted(Constants.doubleFormat))")
                        .font(.title)
                } else {
                    Image(systemName: "doc.viewfinder")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .foregroundColor(isTargetted ? .green : .white)
                        .animation(.default, value: isTargetted)
                    Text("Drop files...")
                        .font(.title)
                }
                Spacer()
            }
            .frame(width: 150, height: 150)
        }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .onDrop(of: [.pdf], isTargeted: $isTargetted) { (files: [NSItemProvider]) in
            Task {
                await organizer.organize(files)
            }
            return true
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var organizer: Organizer = .init()

    static var previews: some View {
        ContentView()
            .environmentObject(organizer)
            .onAppear {
                Task {
                    await organizer.organize([])
                }
            }
    }
}

extension NSItemProvider: @unchecked Sendable {

}
