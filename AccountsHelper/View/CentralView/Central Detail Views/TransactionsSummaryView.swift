import SwiftUI
import CoreData

// MARK: - Extension to sum transactions including splits
extension Array where Element == Transaction {
    func sumByCategoryIncludingSplits() -> [String: Decimal] {
        var result: [String: Decimal] = [:]
        
        for category in Category.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            result[category.description] = 0
        }
        
        for tx in self {
            result[tx.splitCategory.description, default: 0] += tx.splitAmount
            result[tx.splitRemainderCategory.description, default: 0] += tx.splitRemainderAmount
        }
        
        return result
    }
}

// MARK: - Identifiable wrapper for table rows
struct CategoryTotal: Identifiable {
    let id = UUID()
    let category: String
    let total: String
}

// MARK: - Transaction Summary View
struct TransactionsSummaryView: View {
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    private var totalsArray: [CategoryTotal] {
        let byCategory = Array(transactions).sumByCategoryIncludingSplits()
        return Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category in
                let value = byCategory[category.description] ?? 0
                let formatted = String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
                return CategoryTotal(category: category.description, total: formatted)
            }
    }
    
    var body: some View {
        Table(totalsArray) {
            TableColumn("Category", value: \.category)
            TableColumn("Total", value: \.total)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    appState.popCentralView()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .navigationTitle("Transactions Summary")
    }
}
