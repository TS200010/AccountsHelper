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
        appState.selectedInspectorTransactionIDs.compactMap { id in
            try? viewContext.existingObject(with: id) as? Transaction
        }
        .sorted { ($0.transactionDate ?? Date.distantPast) < ($1.transactionDate ?? Date.distantPast) }
    }
    
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
                                    let amount = (transaction.totalAmountInGBP as NSDecimalNumber?)?.doubleValue ?? 0
                                    Text(String(format: "%.2f %@", amount, transaction.currency.description))
                                        .font(.body)
                                        .bold()
                                }
                                
                                // MARK: --- Payee
                                Text(transaction.payee ?? "N/A")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
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
}

