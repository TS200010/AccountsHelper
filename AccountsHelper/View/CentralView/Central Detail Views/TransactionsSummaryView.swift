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

// MARK: - CategoryRow Wrapper
fileprivate struct CategoryRow: Identifiable, Hashable {
    let category: Category
    let total: Decimal
    
    var id: String { category.description }   // stable ID
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}

// MARK: - TransactionsSummaryView
struct TransactionsSummaryView: View {
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // Selection state (single selection)
    @State private var selectedCategoryID: CategoryRow.ID?
    
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    // Derived rows
    private var categoryRows: [CategoryRow] {
        let byCategory = Array(transactions).sumByCategoryIncludingSplits()
        return Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category in
                let total = byCategory[category.description] ?? 0
                return CategoryRow(category: category, total: total)
            }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Table(categoryRows, selection: $selectedCategoryID) {
                TableColumn("Category") { row in
                    HStack {
                        Text(row.category.description)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Print Category") {
                            print("Selected category: \(row.category.description)")
                        }
                    }
                }
                TableColumn("Total") { row in
                    Text(row.totalString)
                }
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
            .padding()
            
            statusBar
        }
        .toolbar { toolbarItems }
        .navigationTitle("Transactions Summary")
    }
    
    // MARK: - Status bar
    private var statusBar: some View {
        HStack {
            Spacer()
            if let selectedID = selectedCategoryID,
               let row = categoryRows.first(where: { $0.id == selectedID }) {
                Text("Selected: \(row.category.description) – \(row.totalString)")
            } else {
                Text("Total Categories: \(categoryRows.count)")
            }
        }
        .padding(8)
        .background(Color.platformWindowBackgroundColor)
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
