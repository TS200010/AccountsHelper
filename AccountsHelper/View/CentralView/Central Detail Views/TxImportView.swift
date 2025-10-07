#if os(macOS)
import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

struct TxImportView<Importer: TxImporter>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState

    // Live fetch ensures view stays in sync with Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
        animation: .default
    )
    private var transactions: FetchedResults<Transaction>

    @State private var statusMessage = "Select a file to start import."
    @State private var importedCount = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("\(Importer.displayName) Importer")
                .font(.title)

            Text(statusMessage)
                .font(.headline)

            HStack {
                Text("Imported: \(importedCount)")
            }

            Button("Select File") {
                selectFile()
            }
            .padding()

            /*
            // 🚧 Optional: show imported transactions directly
            List(transactions) { tx in
                VStack(alignment: .leading) {
                    Text(tx.payee ?? "Unknown Payee")
                    Text(tx.transactionDate ?? Date(), style: .date)
                        .font(.caption)
                }
            }
            */
        }
        .frame(width: 500, height: 250)
    }

    // MARK: - File Selection
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        // Dynamic allowed file types based on Importer
        switch Importer.importType {
        case .csv:
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.title = "Select a \(Importer.displayName) CSV file"
        case .png:
            panel.allowedContentTypes = [.png]
            panel.title = "Select a \(Importer.displayName) PNG file"
        }

        if panel.runModal() == .OK, let url = panel.url {
            startImport(url: url)
        }
    }

    // MARK: - Start Import
    private func startImport(url: URL) {
        statusMessage = "Parsing file..."

        Task { @MainActor in
            let imported = await Importer.importTransactions(
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

            importedCount = imported.count
            statusMessage = "Import complete! Imported \(importedCount)"
        }
    }
}
#endif
