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
            Text("\(Importer.displayName) Importer")
                .font(.title)
            
            Text(statusMessage)
                .font(.headline)
            
            // MARK: --- Imported Count
            HStack {
                Text("Imported: \(importedCount)")
            }
            
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
        .frame(width: 500, height: 250)
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
