import SwiftUI
import CoreData

// MARK: - CategoryPrintRow
struct CategoryPrintRow: Identifiable {
    let id: Int32
    let name: String
    let total: Decimal
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}

// MARK: - CategoryRow Wrapper
fileprivate struct CategoryRow: Identifiable, Hashable {
    let category: Category
    let total: Decimal
    let transactionIDs: [NSManagedObjectID]
    
    var id: Int32 { category.id }
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}

// MARK: --- CategoriesSummaryView
struct CategoriesSummaryView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appStateOptional: AppState?
    
    // MARK: --- FetchRequest
    @FetchRequest private var transactions: FetchedResults<Transaction>
    
    // MARK: --- State
    @State private var selectedCategoryID: Int32?
    
    // MARK: --- Init
    init(predicate: NSPredicate? = nil, isPrinting: Bool = false) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    // MARK: --- Derived Data
    fileprivate var categoryRows: [CategoryRow] {
        let predicate = transactions.nsPredicate ?? NSPredicate(value: true)
        let totals = viewContext.categoryTotals(for: predicate)
        
        return Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category in
                CategoryRow(category: category, total: totals[category] ?? 0, transactionIDs: [])
            }
    }
    
    private var totals: (total: String, totalCR: String, totalDR: String) {
        var total: Decimal = 0
        var totalCR: Decimal = 0
        var totalDR: Decimal = 0
        
        for tx in transactions {
            let amount = tx.totalAmountInGBP
            total += amount
            if amount > 0 { totalCR += amount }
            else if amount < 0 { totalDR += amount }
        }
        
        return (
            total: total.string2f,
            totalCR: totalCR.string2f,
            totalDR: totalDR.string2f
        )
    }
    
    // MARK: --- Body
    var body: some View {
        VStack(alignment: .leading) {
            totalsView
            categoriesTable
                .navigationTitle("Transactions Summary")
        }
        .toolbar { printToolbarItem }
    }
}

// MARK: --- Subviews
extension CategoriesSummaryView {
    
    private var totalsView: some View {
        HStack(spacing: 40) {
            Text("Total: \(totals.total) GBP")
            Text("Total CRs: \(totals.totalCR) GBP")
            Text("Total DRs: \(totals.totalDR) GBP")
        }
        .padding(.horizontal, 10)
    }
    
    private var categoriesTable: some View {
        Table(categoryRows, selection: $selectedCategoryID) {
            TableColumn("Category") { categoryCell(for: $0) }
            TableColumn("Total") { Text($0.totalString) }
        }
        .onChange(of: selectedCategoryID) { _, newValue in
            if let id = newValue,
               let row = categoryRows.first(where: { $0.id == id }) {
                appStateOptional?.selectedInspectorTransactionIDs = row.transactionIDs
                appStateOptional?.selectedInspectorView = .viewCategoryBreakdown
            } else {
                appStateOptional?.selectedInspectorTransactionIDs = []
            }
        }
        #if os(macOS)
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        #endif
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
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
                appStateOptional?.pushCentralView(.browseTransactions(predicate))
            }
        }
    }
    
    private var printToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                printCategoriesSummary()
            } label: {
                Label("Print Summary", systemImage: "printer")
            }
        }
    }
}

// MARK: --- Print Support
extension CategoriesSummaryView {
    
    func printCategoriesSummary() {
        #if os(macOS)
        DispatchQueue.main.async {
            // Prepare totals and rows
            let predicate = transactions.nsPredicate ?? NSPredicate(value: true)
            let totalsDecimal = viewContext.categoryTotals(for: predicate)
            
            let rows = Category.allCases
                .sorted { $0.rawValue < $1.rawValue }
                .map { CategoryPrintRow(id: $0.id, name: $0.description, total: totalsDecimal[$0] ?? 0) }
            
            var total: Decimal = 0
            var totalCR: Decimal = 0
            var totalDR: Decimal = 0
            for tx in transactions {
                let amount = tx.totalAmountInGBP
                total += amount
                if amount > 0 { totalCR += amount }
                else if amount < 0 { totalDR += amount }
            }
            
            // Reconciliation info
            let reconciliation: Reconciliation? = {
                if let recID = appStateOptional?.selectedReconciliationID,
                   let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
                    return rec
                }
                return nil
            }()
            
            var startBalance: Decimal = 0
            var endBalance: Decimal = 0
            if let rec = reconciliation {
                startBalance = rec.endingBalance
                endBalance = startBalance + total
            }
            
            // Build report text
            let report = NSMutableString()
            report.append("Category Summary Report")
            if let rec = reconciliation { report.append(" — \(rec.paymentMethod.description)\n") }
            else { report.append("\n") }
            
            if let rec = reconciliation {
                let period = "\(rec.periodMonth)/\(rec.periodYear)"
                let statementDate = rec.statementDate?.formatted(date: .numeric, time: .omitted) ?? "-"
                let closed = rec.closed ? "Closed" : "Open"
                report.append("\(period) | \(statementDate) | \(closed)\n\n")
            } else { report.append("No reconciliation found\n\n") }
            
            report.append(String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString))
            report.append(String(repeating: "-", count: 46) + "\n")
            for row in rows {
                let paddedName = row.name.padding(toLength: 30, withPad: " ", startingAt: 0)
                let totalStr = row.totalString
                let paddedTotal = String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr
                report.append("\(paddedName)\(paddedTotal)\n")
            }
            
            report.append("\n" + String(repeating: "-", count: 46) + "\n")
            func formatLine(label: String, amount: Decimal) -> String {
                let amountStr = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
                let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
                let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
                return "\(paddedLabel)\(paddedAmount)\n"
            }
            
            report.append(formatLine(label: "Starting Balance", amount: startBalance))
            report.append(formatLine(label: "Total CR", amount: totalCR))
            report.append(formatLine(label: "Total DR", amount: totalDR))
            report.append(formatLine(label: "Net Total", amount: total))
            report.append(formatLine(label: "Ending Balance", amount: endBalance))
            
            // Display report in NSTextView
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 700))
            textView.string = report as String
            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            textView.isEditable = false
            textView.sizeToFit()
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            
            let printOp = NSPrintOperation(view: textView)
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()
        }
        #endif
    }
}
