//
//  AMEXCSVImportView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//
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

struct XAMEXCSVImportView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    @State private var transactions: [TransactionStruct] = []
    @State private var mergeCandidate: MergeCandidate? = nil
    @State private var currentIndex = 0
    @State private var importedCount = 0
    @State private var mergedCount = 0
    @State private var statusMessage = "Select a CSV file to start import."
    
    // Snapshot of existing DB before import begins
    @State private var existingTransactions: [Transaction] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AMEX CSV Importer")
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
            
            // TODO: WIP not working because of TransactionStruct 
//            Alert(
//                title: Text("Merge Transactions?"),
//                message: Text("Existing: \(candidate.existing.payee ?? "")\nNew: \(candidate.new.payee ?? "")"),
//                primaryButton: .default(Text("Merge"), action: {
//                    appState.pushCentralView(
//                        .transactionMergeView(
//                            [candidate.existing, candidate.new],
//                            onComplete: {
//                                // Continue import after merge view finishes
//                                currentIndex += 1
//                                processNextTransaction()
//                            }
//                        )
//                    )
//                }),
//                secondaryButton: .default(Text("Keep Both"), action: {
//                    saveTransaction(candidate.new, merged: false)
//                    currentIndex += 1
//                    processNextTransaction()
//                })
//            )
        }
    }
    
    // MARK: - CSV Selection
    
    private func selectCSVFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["csv"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Select an AMEX CSV file to import"
        
        if panel.runModal() == .OK, let url = panel.url {
            startImport(url: url)
        }
    }
    
    // MARK: - Import Logic
    
    private func startImport(url: URL) {
        statusMessage = "Parsing CSV..."
//        transactions = AMEXCSVImporter.parseCSVToTransactionStruct(fileURL: url)
        currentIndex = 0
        importedCount = 0
        mergedCount = 0
        
        // Snapshot database before starting
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        if let results = try? viewContext.fetch(fetchRequest) {
            existingTransactions = results
        } else {
            existingTransactions = []
        }
        
        processNextTransaction()
    }
    
    func processNextTransaction() {
        DispatchQueue.main.async {
            while self.currentIndex < self.transactions.count {
                let tx = self.transactions[self.currentIndex]
//                print("Processing CSV row \(self.currentIndex): payee='\(tx.payee ?? "")' amount=\(tx.txAmount) date=\(String(describing: tx.transactionDate))")

                // Find candidate in snapshot
                if let existing = AMEXCSVImporter.findMergeCandidateInSnapshot(
                    newTx: tx,
                    snapshot: self.existingTransactions
                ) {
                    // Candidate found, set mergeCandidate to pause for alert
                    self.mergeCandidate = MergeCandidate(existing: existing, new: tx)
                    return
                } else {
                    // No candidate, save and continue
                    self.saveTransaction(tx, merged: false)
                    self.currentIndex += 1
                }
            }

            // Finished all transactions
            self.statusMessage = "CSV import complete! Imported \(self.importedCount), Merged \(self.mergedCount)"
        }
    }

    private func merge(existing: Transaction, into new: TransactionStruct) {
        var newTx = new
        
        if newTx.address?.isEmpty ?? true { newTx.address = existing.address }
        if newTx.category == .unknown { newTx.category = existing.category }
        if newTx.payer == .unknown { newTx.payer = existing.payer }
        if newTx.reference?.isEmpty ?? true { newTx.reference = existing.reference }
        if newTx.extendedDetails?.isEmpty ?? true { newTx.extendedDetails = existing.extendedDetails }

        // Update the correct CSV row using currentIndex
        if currentIndex < transactions.count {
            transactions[currentIndex] = newTx
        }
    }

    
    private func saveTransaction(_ txStruct: TransactionStruct, merged: Bool, existingTx: Transaction? = nil) {
        let tx: Transaction
        
        if let existingTx = existingTx, merged {
            // Update existing transaction in Core Data
            tx = existingTx
        } else {
            // Create new transaction
            tx = Transaction(context: viewContext)
        }
        
        txStruct.apply(to: tx)
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save transaction: \(error)")
        }
        
        importedCount += 1
        if merged { mergedCount += 1 }
        statusMessage = "Imported: \(importedCount), Merged: \(mergedCount)"
    }

}

#endif

// MARK: - AMEXCSVImporter helper

#if os(macOS)
extension TxImporter {
    
    static func findMergeCandidateInSnapshot(
        newTx: TransactionStruct,
        snapshot: [Transaction]
    ) -> Transaction? {
        let calendar = Calendar.current
        return snapshot.first(where: { existing in
            let scaled = (newTx.txAmount * Decimal(100)) as NSDecimalNumber
            let amountMatches = existing.txAmountCD == Int32(truncating: scaled)
            
            let payeeMatches = existing.payee == newTx.payee
            let methodMatches = existing.paymentMethodCD == newTx.paymentMethod.rawValue
            
            var dateMatches = false
            if let existingDate = existing.transactionDate,
               let newDate = newTx.transactionDate {
                if let minus7 = calendar.date(byAdding: .day, value: -7, to: newDate),
                   let plus1 = calendar.date(byAdding: .day, value: 1, to: newDate) {
                    dateMatches = (existingDate >= minus7 && existingDate <= plus1)
                }
            }

           return amountMatches && payeeMatches && methodMatches && dateMatches
        })
    }
}
#endif
