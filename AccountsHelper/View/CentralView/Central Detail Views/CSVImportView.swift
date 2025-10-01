//
//  CSVImportView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 30/09/2025.
//

#if os(macOS)
import SwiftUI
import CoreData
import AppKit

fileprivate struct MergeCandidate: Identifiable {
    let id = UUID()
    let existing: Transaction
    let new: TransactionStruct
}

struct CSVImportView<Importer: CSVImporter>: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    @State private var transactions: [TransactionStruct] = []
    @State private var mergeCandidate: MergeCandidate? = nil
    @State private var currentIndex = 0
    @State private var importedCount = 0
    @State private var mergedCount = 0
    @State private var statusMessage = "Select a CSV file to start import."
    @State private var existingTransactions: [Transaction] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(Importer.displayName) CSV Importer")
                .font(.title)
            
            Text(statusMessage)
                .font(.headline)
            
            HStack {
                Text("Imported: \(importedCount)")
                Text("Merged: \(mergedCount)")
            }
            
            Button("Select CSV File") {
                selectCSVFile()
            }
            .padding()
        }
        .frame(width: 500, height: 250)
        .alert(item: $mergeCandidate) { candidate in
            Alert(
                title: Text("Merge Transactions?"),
                message: Text("Existing: \(candidate.existing.payee ?? "")\nNew: \(candidate.new.payee ?? "")"),
                primaryButton: .default(Text("Merge"), action: {
                    merge(existing: candidate.existing, into: candidate.new)
                    saveTransaction(candidate.new, merged: true, existingTx: candidate.existing)
                    currentIndex += 1
                    processNextTransaction()
                }),
                secondaryButton: .default(Text("Keep Both"), action: {
                    saveTransaction(candidate.new, merged: false)
                    currentIndex += 1
                    processNextTransaction()
                })
            )
        }
    }
    
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
    
    private func startImport(url: URL) {
        statusMessage = "Parsing CSV..."
        transactions = Importer.parseCSVToTransactionStruct(fileURL: url)
        currentIndex = 0
        importedCount = 0
        mergedCount = 0
        
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        if let results = try? viewContext.fetch(fetchRequest) {
            existingTransactions = results
        } else {
            existingTransactions = []
        }
        
        processNextTransaction()
    }
    
    private func processNextTransaction() {
        DispatchQueue.main.async {
            while currentIndex < transactions.count {
                let tx = transactions[currentIndex]
                
                if let existing = Importer.findMergeCandidateInSnapshot(newTx: tx, snapshot: existingTransactions) {
                    mergeCandidate = MergeCandidate(existing: existing, new: tx)
                    return
                } else {
                    saveTransaction(tx, merged: false)
                    currentIndex += 1
                }
            }
            statusMessage = "CSV import complete! Imported \(importedCount), Merged \(mergedCount)"
        }
    }
    
    private func merge(existing: Transaction, into new: TransactionStruct) {
        var newTx = new
        
        if newTx.address?.isEmpty ?? true { newTx.address = existing.address }
        if newTx.category == .unknown { newTx.category = existing.category }
        if newTx.payer == .unknown { newTx.payer = existing.payer }
        if newTx.reference?.isEmpty ?? true { newTx.reference = existing.reference }
        if newTx.extendedDetails?.isEmpty ?? true { newTx.extendedDetails = existing.extendedDetails }
        
        if currentIndex < transactions.count {
            transactions[currentIndex] = newTx
        }
    }
    
    private func saveTransaction(_ txStruct: TransactionStruct, merged: Bool, existingTx: Transaction? = nil) {
        let tx: Transaction
        
        if let existingTx = existingTx, merged {
            tx = existingTx
        } else {
            tx = Transaction(context: viewContext)
        }
        
        txStruct.apply(to: tx)
        
        do { try viewContext.save() } catch { print("Failed to save transaction: \(error)") }
        
        importedCount += 1
        if merged { mergedCount += 1 }
        statusMessage = "Imported: \(importedCount), Merged: \(mergedCount)"
    }
}

#endif
