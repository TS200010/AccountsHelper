
import SwiftUI
import CoreData

//
// Some variables marked as internal as they are used by the printing system located in different files
// ====================================================================================================
//

struct CategoriesSummaryView: View {
    
    let vm: CategoriesSummaryVM
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) internal var viewContext
    @Environment(AppState.self) internal var appState
    @AppStorageEnum("showCurrencySymbols", defaultValue: .always)
    var showCurrencySymbols: ShowCurrencySymbolsEnum
    
    // MARK: --- State
    @State private var selectedCategoryID: Int32?
    
    // MARK: --- FetchRequest
//    @FetchRequest private var transactions: FetchedResults<Transaction>

    // MARK: --- Resolved aggregate
    var reconciliation: Reconciliation? {
        guard let id = appState.selectedReconciliationID else { return nil }
        return try? viewContext.existingObject(with: id) as? Reconciliation
    }
    
    // MARK: --- Derived data
    private var transactions: [Transaction] {
        guard
            let reconciliation,
            let set = reconciliation.transactions as? Set<Transaction>
        else {
            return []
        }
        return set.sorted {
            ($0.transactionDate ?? .distantPast) <
            ($1.transactionDate ?? .distantPast)
        }
    }
    
    // MARK: --- Local Variables
    private var currency: Currency? {
        transactions.first?.account.currency
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
        let currentCurrency = currency ?? .unknown

        // Group postings by category
        let groupedPostings = Dictionary(grouping: transactions.postings, by: { $0.category })

        return Category.allCases.map { category in
            let postingsForCategory = groupedPostings[category] ?? []
            let total = postingsForCategory.reduce(Decimal(0)) { sum, posting in
                sum + posting.amount
            }
            let ids = postingsForCategory.compactMap { posting in
                // Find all transaction IDs for this category
                transactions.first(where: { tx in
                    // Check if transaction contributes to this posting
                    tx.splitCategory == posting.category || tx.splitRemainderCategory == posting.category
                })?.objectID
            }

            return CategoryRow(category: category,
                               total: total,
                               transactionIDs: ids,
                               currency: currentCurrency)
        }
    }
    
    // MARK: --- Body
    var body: some View {
        VStack(alignment: .leading) {
            headerView
            categoriesTable
                .frame(minWidth: 300, idealWidth: 500, maxWidth: 600) // adjust as needed

        }
        .toolbar { printToolbarItem }
    }
}

// MARK: --- SUBVIEWS
extension CategoriesSummaryView {
    
    private var printToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                let report = CategoriesSummaryReportRenderer.buildReport(from: vm)
                printReport(report)
//                printCategoriesSummary()
            } label: {
                Label("Print Summary", systemImage: "printer")
            }
        }
    }
    
    // MARK: --- HeaderView (Balances and Totals)
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Starting Balance: \(vm.totals.startBalance.formattedAsCurrency(vm.totals.currency))")
                .font(.headline)
            
            HStack(spacing: 40) {
                Text("Total CRs: \(vm.totals.totalCR.formattedAsCurrency(vm.totals.currency))")
                Text("Total DRs: \(vm.totals.totalDR.formattedAsCurrency(vm.totals.currency))")
                Text("Net Total: \(vm.totals.total.formattedAsCurrency(vm.totals.currency))")
            }
            .font(.subheadline)
            
            Text("Ending Balance: \(vm.totals.endBalance.formattedAsCurrency(vm.totals.currency))")
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
                    Text( AmountFormatter.anyAmountAsString(amount: row.total, currency: row.currency, withSymbol: showCurrencySymbols) )
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                }
            }
        }
        .id(showCurrencySymbols) // Forces the Table to rebuild when this changes
        .onChange(of: selectedCategoryID) { _, newValue in
            guard let id = newValue,
                  let row = categoryRows.first(where: { $0.id == id }),
                  let reconciliation = reconciliation else {
                appState.selectedInspectorTransactionIDs = []
                return
            }

            // Build the same predicate we use for the context menu
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "reconciliation == %@", reconciliation),
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "categoryCD == %d", row.id),
                    NSPredicate(format: "splitCategoryCD == %d", row.id)
                ])
//                NSPredicate(format: "categoryCD == %d", row.id)
            ])

            // Create fetch request and assign predicate
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = predicate

            // Fetch transactions for the inspector
            let transactionsForInspector = (try? viewContext.fetch(fetchRequest)) ?? []

            // Pass their objectIDs to the inspector
            appState.selectedInspectorTransactionIDs = transactionsForInspector.map { $0.objectID }

            // Update the inspector view
            appState.selectedInspectorView = .viewCategoryBreakdown

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
                guard let reconciliation = reconciliation else { return }

                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    // Must belong to this reconciliation
                    NSPredicate(format: "reconciliation == %@", reconciliation),

                    // Match the row's category in any relevant field
                    NSCompoundPredicate(orPredicateWithSubpredicates: [
                        NSPredicate(format: "categoryCD == %d", row.id),
                        NSPredicate(format: "splitCategoryCD == %d", row.id)
                    ])
                    // Must match the row's category
//                    NSPredicate(format: "categoryCD == %d", row.id),

                    // Optional: if you want to limit to a specific account as well
                    // NSPredicate(format: "accountCD == %d", someAccountID)
                ])
//                let predicate = NSPredicate(format: "categoryCD == %d", row.id)
                appState.pushCentralView(.browseTransactions(predicate))
            }
        }
    }
}

