import SwiftUI
import CoreData

// MARK: - Extension to sum transactions including splits
extension Array where Element == Transaction {
    func sumByCategoryIncludingSplitsInGBP() -> [Category: Decimal] {
        var result: [Category: Decimal] = [:]
        
        for category in Category.allCases {
            result[category] = 0
        }
        
        for tx in self {
            result[tx.splitCategory, default: 0] += tx.splitAmountInGBP
            result[tx.splitRemainderCategory, default: 0] += tx.splitRemainderAmountInGBP
        }
        
        return result
    }
}

extension Decimal {
    var string2f: String {
        String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }
}

//extension Array where Element == Transaction {
//    var totalInGBP: Decimal {
//        self.reduce(0) { $0 + $1.totalAmountInGBP }
//    }
//
//    var totalCreditsInGBP: Decimal {
//        self.filter { $0.totalAmountInGBP > 0 }
//            .reduce(0) { $0 + $1.totalAmountInGBP }
//    }
//
//    var totalDebitsInGBP: Decimal {
//        self.filter { $0.totalAmountInGBP < 0 }
//            .reduce(0) { $0 + $1.totalAmountInGBP }
//    }
//}

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
        let byCategory = Array(transactions).sumByCategoryIncludingSplitsInGBP()
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
    
    // Precompute totals as formatted strings
    private var totals: (total: String, totalCR: String, totalDR: String) {
        var total: Decimal = 0
        var totalCR: Decimal = 0
        var totalDR: Decimal = 0

        for tx in transactions {
            let amount = tx.totalAmountInGBP
            total += amount
            if amount > 0 {
                totalCR += amount
            } else if amount < 0 {
                totalDR += amount
            }
        }

        return (
            total: total.string2f,
            totalCR: totalCR.string2f,
            totalDR: totalDR.string2f,
        )
    }
    
    // MARK: - Body
    var body: some View {

        VStack(alignment: .leading ) {
            HStack ( spacing: 40) {
                    Text("Total: \(totals.total) GBP")
                    Text("Total CRs: \(totals.totalCR) GBP")
                    Text("Total DRs: \(totals.totalDR) GBP")
                    //                Text("Previous Balance: \(String(format: "%.2f", NSDecimalNumber(decimal: previousBalance).doubleValue)) GBP")
                    //                Text("New Balance: \(String(format: "%.2f", NSDecimalNumber(decimal: newBalance).doubleValue)) GBP")
                    
                }
                .padding(0)
            

            categoriesTable
                .toolbar { toolbarItems }
                .navigationTitle("Transactions Summary")
        }
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
