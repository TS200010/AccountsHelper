#if os(macOS)
import SwiftUI
import CoreData
import AppKit

struct CSVImportView<Importer: CSVImporter>: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState

    @State private var transactions: [Transaction] = []
    @State private var statusMessage = "Select a CSV file to start import."
    @State private var importedCount = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("\(Importer.displayName) CSV Importer")
                .font(.title)

            Text(statusMessage)
                .font(.headline)

            HStack {
                Text("Imported: \(importedCount)")
            }

            Button("Select CSV File") {
                selectCSVFile()
            }
            .padding()
        }
        .frame(width: 500, height: 250)
    }

    // MARK: - File Selection
    private func selectCSVFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["csv"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Select a \(Importer.displayName) CSV file"

        if panel.runModal() == .OK, let url = panel.url {
            startImport(url: url)
        }
    }

    // MARK: - Start Import
    private func startImport(url: URL) {
        statusMessage = "Parsing CSV..."

        Task { @MainActor in
            transactions = await Importer.importTransactions(
                fileURL: url,
                context: viewContext,
                mergeHandler: { existing, new in
                    // Show merge dialog
                    await withCheckedContinuation { continuation in
                        appState.pushCentralView(
                            .transactionMergeView([existing, new]) {
                                continuation.resume(returning: existing)
                            }
                        )
                    }
                }
            )

            importedCount = transactions.count
            statusMessage = "CSV import complete! Imported \(importedCount)"
        }
    }
}

#endif
