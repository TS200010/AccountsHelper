
import SwiftUI
import CoreData

//
// Some variables marked as internal as they are used by the printing system located in different files
// ====================================================================================================
//

struct CategoriesSummaryView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) internal var viewContext
    @Environment(AppState.self) internal var appState
    @AppStorageEnum("showCurrencySymbols", defaultValue: .always)
    var showCurrencySymbols: ShowCurrencySymbolsEnum
    
    
    // MARK: --- FetchRequest
    @FetchRequest private var transactions: FetchedResults<Transaction>
    
    // MARK: --- State
    @State private var selectedCategoryID: Int32?
    
    // MARK: --- Init
    init(predicate: NSPredicate? = nil, isPrinting: Bool = false) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
            predicate: predicate
        )
    }
    
    // MARK: --- Local Variables
    private var currency: Currency? {
        transactions.first?.paymentMethod.currency
    }
    
    // MARK: --- SummaryTotals
    internal struct SummaryTotals {
        var startBalance: Decimal = 0
        var endBalance: Decimal = 0
        var totalCR: Decimal = 0
        var totalDR: Decimal = 0
        var total: Decimal { get { totalCR + totalDR } }
        var currency: Currency = .unknown
    }
    
    // MARK: --- Computed summaryTotals
    internal var summaryTotals: SummaryTotals {
        var result = SummaryTotals()
        result.currency = currency ?? .unknown
        
        // Identify reconciliation if present
        let reconciliation: Reconciliation? = {
            if let recID = appState.selectedReconciliationID,
               let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
                return rec
            }
            return nil
        }()
        
        // Compute start balance
        if let rec = reconciliation {
            result.startBalance = rec.previousEndingBalance
        }
        
        // Sum all tx amounts
        for tx in transactions {
            let amount = tx.txAmount
            if amount < 0 {
                result.totalCR += amount
            } else if amount > 0 {
                result.totalDR += amount
            }
        }
        
        // Compute ending balance
        result.endBalance = result.startBalance - result.total
        return result
    }
    
    // MARK: --- CategoryRow
    internal struct CategoryRow: Identifiable, Hashable {
        let category: Category
        let total: Decimal
        let transactionIDs: [NSManagedObjectID]
        let currency: Currency
        var id: Int32 { category.id }
    }

    // MARK: --- CategoryRows
    internal var categoryRows: [CategoryRow] {
        let grouped = Dictionary(grouping: transactions) { (tx: Transaction) in
            tx.category
        }
        let currentCurrency = currency ?? .unknown
        
        return Category.allCases.map { category in
            let txs = grouped[category] ?? []
            let total = txs.reduce(Decimal(0)) { sum, tx in
                sum + tx.txAmount
            }
            let ids = txs.map { $0.objectID }
            
            return CategoryRow(category: category, total: total, transactionIDs: ids, currency: currentCurrency )
        }
    }
    
    // MARK: --- Body
    var body: some View {
        VStack(alignment: .leading) {
            headerView
            categoriesTable
                .frame(minWidth: 300, idealWidth: 500, maxWidth: 600) // adjust as needed
            
//                .navigationTitle("Transactions Summary")
        }
        .toolbar { printToolbarItem }
    }
}

// MARK: --- SUBVIEWS
extension CategoriesSummaryView {
    
    private var printToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                printCategoriesSummary()
            } label: {
                Label("Print Summary", systemImage: "printer")
            }
        }
    }
    
    // MARK: --- HeaderView (Balances and Totals)
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Starting Balance: \(summaryTotals.startBalance.formattedAsCurrency(summaryTotals.currency))")
                .font(.headline)
            
            HStack(spacing: 40) {
                Text("Total CRs: \(summaryTotals.totalCR.formattedAsCurrency(summaryTotals.currency))")
                Text("Total DRs: \(summaryTotals.totalDR.formattedAsCurrency(summaryTotals.currency))")
                Text("Net Total: \(summaryTotals.total.formattedAsCurrency(summaryTotals.currency))")
            }
            .font(.subheadline)
            
            Text("Ending Balance: \(summaryTotals.endBalance.formattedAsCurrency(summaryTotals.currency))")
                .font(.headline)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
    
    // MARK: --- CategoriesTable
    private var categoriesTable: some View {
        Table(categoryRows, selection: $selectedCategoryID) {
            TableColumn("Category") { categoryCell(for: $0) }
            TableColumn("Total") { row in
                HStack {
                    Text( Transaction.anyAmountAsString(amount: row.total, currency: row.currency, withSymbol: showCurrencySymbols) )
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                }
            }
        }
        .id(showCurrencySymbols) // Forces the Table to rebuild when this changes
        .onChange(of: selectedCategoryID) { _, newValue in
            if let id = newValue,
               let row = categoryRows.first(where: { $0.id == id }) {
                appState.selectedInspectorTransactionIDs = row.transactionIDs
                appState.selectedInspectorView = .viewCategoryBreakdown
            } else {
                appState.selectedInspectorTransactionIDs = []
            }
        }
        #if os(macOS)
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        #endif
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // MARK: --- CategoryCell
    @ViewBuilder
    private func categoryCell(for row: CategoryRow) -> some View {
        HStack {
            Text(row.category.description)
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Transactions") {
                let predicate = NSPredicate(format: "categoryCD == %d", row.id)
                appState.pushCentralView(.browseTransactions(predicate))
            }
        }
    }
}

