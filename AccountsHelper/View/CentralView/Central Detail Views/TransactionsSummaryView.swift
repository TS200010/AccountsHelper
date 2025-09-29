//
//  TransactionsSummaryView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 28/09/2025.
//

import SwiftUI
import CoreData

// MARK: - Extension to sum transactions including splits
extension Array where Element == Transaction {
    
    func sumByCategoryIncludingSplits() -> [String: Decimal] {
        var result: [String: Decimal] = [:]
        
        // Initialize all categories with zero
        let categoriesByRawValue = Category.allCases.sorted { $0.rawValue < $1.rawValue }
        for category in categoriesByRawValue {
            result[category.description] = 0
        }
        
        // Sum split amounts and remainder amounts
        for tx in self {
            let splitCategory = tx.splitCategory.description
            result[splitCategory, default: 0] += tx.splitAmount
            
            let remainderCategory = tx.splitRemainderCategory.description
            result[remainderCategory, default: 0] += tx.splitRemainderAmount
        }
        
        return result
    }
}

// MARK: - Transaction Summary View
struct TransactionsSummaryView: View {
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: - Initializers
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    init(predicate: NSPredicate) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    // MARK: - Totals formatted as strings in rawValue order
    private var totalsArray: [(category: Category, total: String)] {
        let byCategory = Array(transactions).sumByCategoryIncludingSplits()
        
        return Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category in
                let value = byCategory[category.description] ?? 0
                let formatted = String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
                return (category, formatted)
            }
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(totalsArray, id: \.category) { item in
                    HStack {
                        Text(item.category.description)
                            .font(.body)
                        Spacer()
                        Text(item.total)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .toolbar { toolbarItems }
        .navigationTitle("Transactions Summary")
    }
    
    // MARK: - Toolbar
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigation) {
                Button {
                    appState.popCentralView()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }
}
