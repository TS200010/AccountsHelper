//
//  TxImportView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

#if os(macOS)
import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

// MARK: --- Tx Import View
struct TxImportView<Importer: TxImporter>: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: --- Fetch Request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
        animation: .default
    )
    private var transactions: FetchedResults<Transaction>
    
    // MARK: --- Local State
    @State private var statusMessage = "Select a file to start import."
    @State private var importedCount = 0
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: --- Header
            Text("\(Importer.displayName)")
                .font(.title)
            
            Text(statusMessage)
                .font(.headline)
//                .lineLimit(nil)
//
//            // MARK: --- Imported Count
//            HStack {
//                Text("Imported Do We See This?: \(importedCount)")
//            }
            
            // MARK: --- Select File Button
            Button("Select File") {
                selectFile()
            }
            .padding()
            
            /*
            // MARK: --- Optional: Imported Transactions List
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
        .frame(width: 800, height: 500)
    }
    
    // MARK: --- File Selection
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
    
    // MARK: --- Start Import
    private func startImport(url: URL) {
        statusMessage = "Parsing file..."
        
        Task { @MainActor in
            let importSummary = await Importer.importTransactions(
                fileURL: url,
                context: viewContext,
                mergeHandler: { existing, new in
                    // Show merge dialog
                    await withCheckedContinuation { continuation in
                        appState.pushCentralView(
                            .mergeTransactionsView([existing, new]) { result in
                                // result is the MergeResult enum from the view
                                continuation.resume(returning: result) // <-- now correct type
                            }
                        )
                    }
                }
            )
            
            statusMessage = "Import complete.\nProcessed \(importSummary.processedCount) transactions\n"
            statusMessage += "Merged: \(importSummary.mergedCount)\nKept Existing: \(importSummary.keepExistingCount)\nKept New: \(importSummary.keepNewCount)\nKept Both: \(importSummary.keepBothCount)"
            if importSummary.processedCount == 0 {
                statusMessage += "\n\nNo transactions processed. Did you export all Columns?"
            }
        }
    }
}
#endif
