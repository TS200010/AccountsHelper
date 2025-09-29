import SwiftUI
import CoreData

// MARK: - Extension to sum transactions including splits
extension Array where Element == Transaction {
    func sumByCategoryIncludingSplits() -> [Category: Decimal] {
        var result: [Category: Decimal] = [:]
        for category in Category.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            result[category] = 0
        }
        for tx in self {
            result[tx.splitCategory, default: 0] += tx.splitAmount
            result[tx.splitRemainderCategory, default: 0] += tx.splitRemainderAmount
        }
        return result
    }
}

// MARK: - CategoryRow Wrapper
fileprivate struct CategoryRow: Identifiable, Hashable {
    let category: Category
    let total: Decimal
    
    var id: Int32 { category.id } // stable ID for selection
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}

// MARK: - TransactionsSummaryView
struct TransactionsSummaryView: View {
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // Single selection
    @State private var selectedCategoryID: Int32?
    
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    // Derived rows
    fileprivate var categoryRows: [CategoryRow] {
        let byCategory = Array(transactions).sumByCategoryIncludingSplits()
        let rows = Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category -> CategoryRow in
                let total = byCategory[category] ?? 0
                let row = CategoryRow(category: category, total: total)
                print("CategoryRow created: \(row.category.description), id: \(row.id)")
                return row
            }
        return rows
    }
    
    // MARK: - Table
    private var categoriesTable: some View {
        Table(categoryRows, selection: $selectedCategoryID) {
            TableColumn("Category") { row in
                categoryCell(for: row)
            }
            TableColumn("Total") { row in
                Text(row.totalString)
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // MARK: - Category Cell with Context Menu
    @ViewBuilder
    private func categoryCell(for row: CategoryRow) -> some View {
        HStack {
            Text(row.category.description)
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Print Category") {
                print("Selected category: \(row.category.description)")
            }
            Button("Transactions") {
                let predicate = NSPredicate(format: "categoryCD == %d", row.id)
//                DispatchQueue.main.async {
                    appState.pushCentralView(.browseTransactions( predicate) )
//                }
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        categoriesTable
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
