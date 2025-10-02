//
//  viewCategoryBreakdown( txs: [ id ]).swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 09/09/2025.
//

import SwiftUI
import CoreData

struct InspectorCategoryBreakdown: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // DateFormatter for displaying date only
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium  // e.g., "Oct 2, 2025"
        df.timeStyle = .none
        return df
    }()
    
    // Fetch transactions from IDs stored in AppState
    var transactions: [Transaction] {
        appState.selectedInspectorTransactionIDs.compactMap { id in
            try? viewContext.existingObject(with: id) as? Transaction
        }
        .sorted { ($0.transactionDate ?? Date.distantPast) < ($1.transactionDate ?? Date.distantPast) }
    }
    
    var body: some View {
        GeometryReader { geo in
            if transactions.isEmpty {
                Text("No Transactions for Selected Category")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transactions for Selected Category")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 10)
                        
                        ForEach(transactions, id: \.objectID) { transaction in
                            VStack(alignment: .leading, spacing: 4) {
                                
                                // Line 1: Date and Amount
                                HStack {
                                    Text(transaction.transactionDate != nil ? dateFormatter.string(from: transaction.transactionDate!) : "N/A")
                                        .font(.body)
                                    Spacer()
                                    let amount = (transaction.totalAmountInGBP as NSDecimalNumber?)?.doubleValue ?? 0
                                    Text(String(format: "%.2f %@", amount, transaction.currency.description))
                                        .font(.body)
                                        .bold()
                                }
                                
                                // Line 2: Payee
                                Text(transaction.payee ?? "N/A")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
        }
    }
}

