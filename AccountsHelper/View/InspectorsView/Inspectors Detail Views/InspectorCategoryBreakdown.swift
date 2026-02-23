//
//  InspectCategoryBreakdown.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 09/09/2025.
//

import SwiftUI
import CoreData

// MARK: --- InspectCategoryBreakdown
struct InspectCategoryBreakdown: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: --- Date Formatter
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium   // e.g., "Oct 2, 2025"
        df.timeStyle = .none
        return df
    }()
    
    // MARK: --- Transactions from AppState
    private var transactions: [Transaction] {
        
//        for id in appState.selectedInspectorTransactionIDs {
//            if let obj = try? viewContext.existingObject(with: id) {
//                print("ID:", id)
//                print("Entity:", obj.entity.name ?? "nil")
//                print("Object:", obj)
//                print("---")
//            }
//        }
        
        // DEBUG: check for duplicate IDs in AppState
//        let duplicateIDs = Dictionary(
//            grouping: appState.selectedInspectorTransactionIDs,
//            by: { $0 }
//        ).filter { $1.count > 1 }

//        if !duplicateIDs.isEmpty {
//            print("⚠️ Duplicate NSManagedObjectIDs in selectedInspectorTransactionIDs:")
//            for (id, occurrences) in duplicateIDs {
//                print("ID \(id) occurs \(occurrences.count) times")
//            }
//        } else {
//            print("✅ No duplicate IDs in selectedInspectorTransactionIDs")
//        }
        
        // Step 1: Fetch all Transactions from IDs
        let fetchedTransactions: [Transaction] = appState.selectedInspectorTransactionIDs.compactMap { id in
            do {
                return try viewContext.existingObject(with: id) as? Transaction
            } catch {
                print("Warning: Transaction with ID \(id) not found")
                return nil
            }
        }

        // Step 2: Detect duplicate objectIDs
//        let duplicates = Dictionary(grouping: fetchedTransactions, by: { $0.objectID })
//            .filter { $1.count > 1 }
//        if !duplicates.isEmpty {
//            print("⚠️ Duplicate Transactions detected:")
//            for (id, txs) in duplicates {
//                print("ID: \(id) appears \(txs.count) times. Payees: \(txs.compactMap { $0.payee })")
//            }
//        }

        // Step 3: Deduplicate just in case
//        let uniqueTransactions = Array(Set(fetchedTransactions))

        // Step 4: Sort by date
        return fetchedTransactions.sorted { ($0.transactionDate ?? Date.distantPast) < ($1.transactionDate ?? Date.distantPast) }
    }
//    private var transactions: [Transaction] {
//        appState.selectedInspectorTransactionIDs.compactMap { id in
//            try? viewContext.existingObject(with: id) as? Transaction
//        }
//        .sorted { ($0.transactionDate ?? Date.distantPast) < ($1.transactionDate ?? Date.distantPast) }
//    }
    
    // MARK: --- Body
    var body: some View {
        if transactions.count > 0 {
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // MARK: --- Header
                        Text("Transactions for Selected Category")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 10)
                        
                        // MARK: --- Transaction List
                        ForEach(transactions, id: \.objectID) { transaction in
                            VStack(alignment: .leading, spacing: 4) {
                                
                                // MARK: --- Date and Amount
                                HStack {
                                    Text(transaction.transactionDate != nil ? dateFormatter.string(from: transaction.transactionDate!) : "N/A")
                                        .font(.body)
                                    Spacer()
                                    let amount = (transaction.totalAmountInUKL as NSDecimalNumber?)?.doubleValue ?? 0
                                    Text(String(format: "%.2f %@", amount, transaction.currency.description))
                                        .font(.body)
                                        .bold()
                                }
                                
                                // MARK: --- Payee
                                Text(transaction.payee ?? "N/A")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // MARK: --- Split List
                                splitList(for: transaction )
 
                                
                            }
                            .padding()
                            //                        .background(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appState.selectedTransactionID == transaction.objectID ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            )
                            .cornerRadius(12)
                            .onTapGesture {
                                appState.selectedTransactionID = transaction.objectID
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
        } else {
            VStack {
                Text("No Category Selected")
                Text("Or Category has no Transactions")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(.gray)
        }
    }
    
    // MARK: --- Split List
    @ViewBuilder
    private func splitList(for transaction: Transaction) -> some View {
        // Filter out zero amounts if needed
        let filteredPostings = transaction.postings.filter { $0.amount != 0 }
        
        @AppStorageEnum("showCurrencySymbols", defaultValue: .always)
        var showCurrencySymbols: ShowCurrencySymbolsEnum

        VStack(alignment: .leading, spacing: 2) {
            ForEach(filteredPostings, id: \.self) { posting in
                HStack {
                    Text(posting.category.description)
                    Spacer()
                    Text(AmountFormatter.anyAmountAsString(
                            amount: posting.amount,
                            currency: transaction.currency,
                            withSymbol: showCurrencySymbols ))
                        .bold()
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
}

