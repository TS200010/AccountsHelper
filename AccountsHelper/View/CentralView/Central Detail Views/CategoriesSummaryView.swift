
import SwiftUI
import CoreData

struct CategoriesSummaryView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appState
    
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
    fileprivate struct SummaryTotals {
        var startBalance: Decimal = 0
        var endBalance: Decimal = 0
        var totalCR: Decimal = 0
        var totalDR: Decimal = 0
        var total: Decimal { get { totalCR + totalDR } }
        var currency: Currency = .unknown
    }
    
    // MARK: --- Computed summaryTotals
    private var summaryTotals: SummaryTotals {
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
    fileprivate struct CategoryRow: Identifiable, Hashable {
        let category: Category
        let total: Decimal
        let transactionIDs: [NSManagedObjectID]
        
        var id: Int32 { category.id }
        
        var totalString: String {
            String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
        }
    }

    // MARK: --- CategoryRows
    fileprivate var categoryRows: [CategoryRow] {
        let grouped = Dictionary(grouping: transactions) { (tx: Transaction) in
            tx.category
        }
        
        return Category.allCases.map { category in
            let txs = grouped[category] ?? []
            let total = txs.reduce(Decimal(0)) { sum, tx in
                sum + tx.txAmount
            }
            let ids = txs.map { $0.objectID }
            
            return CategoryRow(category: category, total: total, transactionIDs: ids)
        }
    }
    
    // MARK: --- Body
    var body: some View {
        VStack(alignment: .leading) {
            headerView
            categoriesTable
                .navigationTitle("Transactions Summary")
        }
        .toolbar { printToolbarItem }
    }
}

// MARK: --- SUBVIEWS
extension CategoriesSummaryView {
    
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
            TableColumn("Total") { Text($0.totalString) }
        }
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

// MARK: --- PRINT SUPPORT
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
    
    func printCategoriesSummary() {
        #if os(macOS)
        DispatchQueue.main.async {
            let totals = summaryTotals
            let rows = categoryRows
            
            let report = NSMutableString()
            report.append("Category Summary Report")
            if let recID = appState.selectedReconciliationID,
               let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
                report.append(" — \(rec.paymentMethod.description)\n")
            } else {
                report.append("\n")
            }
            
            report.append("\n")
            report.append(String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString))
            report.append(String(repeating: "-", count: 46) + "\n")
            
            for row in rows {
                let paddedName = row.category.description.padding(toLength: 30, withPad: " ", startingAt: 0)
                let totalStr = row.totalString
                let paddedTotal = String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr
                report.append("\(paddedName)\(paddedTotal)\n")
            }
            
            report.append("\n" + String(repeating: "-", count: 46) + "\n")
            
            func formatLine(_ label: String, _ amount: Decimal) -> String {
                let amountStr = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
                let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
                let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
                return "\(paddedLabel)\(paddedAmount)\n"
            }
            
            report.append(formatLine("Starting Balance", totals.startBalance))
            report.append(formatLine("Total CR", totals.totalCR))
            report.append(formatLine("Total DR", totals.totalDR))
            report.append(formatLine("Net Total", totals.total))
            report.append(formatLine("Ending Balance", totals.endBalance))
            
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
//import SwiftUI
//import CoreData
//
//
//struct CategoriesSummaryView: View {
//    
//    // MARK: --- Environment
//    @Environment(\.managedObjectContext) private var viewContext
//    @Environment(AppState.self) private var appState
//    
//    // MARK: --- FetchRequest
//    @FetchRequest private var transactions: FetchedResults<Transaction>
//    
//    // MARK: --- State
//    @State private var selectedCategoryID: Int32?
//    
//
//    // MARK: --- Local Variables
//    private var currency: Currency? {
//        // The Currency will be the currency of the paymentMethod of the Transaction.
//        // ... Thats what it will be designated in
//        transactions.first?.paymentMethod.currency
//    }
//    
//    // MARK: --- Init
//    init(predicate: NSPredicate? = nil, isPrinting: Bool = false) {
//        _transactions = FetchRequest(
//            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
//            predicate: predicate
//        )
//    }
//    
//    // MARK: --- CategoryRow
//    fileprivate struct CategoryRow: Identifiable, Hashable {
//        let category: Category
//        let total: Decimal
//        let transactionIDs: [NSManagedObjectID]
//        
//        var id: Int32 { category.id }
//        
//        var totalString: String {
//            String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
//        }
//    }
//
//    // MARK: --- CategoryRows
//    fileprivate var categoryRows: [CategoryRow] {
//        // Group all transactions by category (defaulting to .unknown)
//        let grouped = Dictionary(grouping: transactions) { (tx: Transaction) in
//            tx.category
//        }
//        
//        // Iterate over all categories in the defined enum order
//        return Category.allCases.map { category in
//            let txs = grouped[category] ?? []
//            let total = txs.reduce(Decimal(0)) { sum, tx in
////                sum + tx.totalAmountInGBP
//                sum + tx.txAmount
//            }
//            let ids = txs.map { $0.objectID }
//            
//            return CategoryRow(category: category, total: total, transactionIDs: ids)
//        }
//    }
//
//    // MARK: --- Body
//    var body: some View {
//        VStack(alignment: .leading) {
//            totalsView
//            categoriesTable
//                .navigationTitle("Transactions Summary")
//        }
//        .toolbar { printToolbarItem }
//    }
//}
//
//
//// MARK: --- SUBVIEWS
//extension CategoriesSummaryView {
//    
//    // MARK: --- Totals
//    private var totals: (total: String, totalCR: String, totalDR: String) {
//        var total: Decimal = 0
//        var totalCR: Decimal = 0
//        var totalDR: Decimal = 0
//        
//        for tx in transactions {
////            let amount = tx.totalAmountInGBP
//            let amount = tx.txAmount
//            total += amount
//            if amount > 0 { totalCR += amount }
//            else if amount < 0 { totalDR += amount }
//        }
//        
//        return (
//            total: total.formattedAsCurrency( currency ?? .unknown ),
//            totalCR: totalCR.formattedAsCurrency( currency ?? .unknown ),
//            totalDR: totalDR.formattedAsCurrency( currency ?? .unknown )
////            total: total.string2f,
////            totalCR: totalCR.string2f,
////            totalDR: totalDR.string2f
//        )
//    }
//    
//    // MARK: --- TotalsView
//    private var totalsView: some View {
//        HStack(spacing: 40) {
//            Text("Total: \(totals.total)")
//            Text("Total CRs: \(totals.totalCR)")
//            Text("Total DRs: \(totals.totalDR)")
////            Text("Total: \(totals.total) GBP")
////            Text("Total CRs: \(totals.totalCR) GBP")
////            Text("Total DRs: \(totals.totalDR) GBP")
//        }
//        .padding(.horizontal, 10)
//    }
//    
//    // MARK: --- CategoriesTable
//    private var categoriesTable: some View {
//        Table(categoryRows, selection: $selectedCategoryID) {
//            TableColumn("Category") { categoryCell(for: $0) }
//            TableColumn("Total") { Text($0.totalString) }
//        }
//        .onChange(of: selectedCategoryID) { _, newValue in
//            if let id = newValue,
//               let row = categoryRows.first(where: { $0.id == id }) {
//                print(row)
//                appState.selectedInspectorTransactionIDs = row.transactionIDs
//                appState.selectedInspectorView = .viewCategoryBreakdown
//            } else {
//                appState.selectedInspectorTransactionIDs = []
//            }
//        }
//        #if os(macOS)
//        .tableStyle(.inset(alternatesRowBackgrounds: true))
//        #endif
//        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
//        .padding()
//    }
//    
//    // MARK: --- CategoryCell
//    @ViewBuilder
//    private func categoryCell(for row: CategoryRow) -> some View {
//        HStack {
//            Text(row.category.description)
//            Spacer()
//        }
//        .contentShape(Rectangle())
//        .contextMenu {
//            Button("Transactions") {
//                let predicate = NSPredicate(format: "categoryCD == %d", row.id)
//                appState.pushCentralView(.browseTransactions(predicate))
//            }
//        }
//    }
//}
//
//
//// MARK: --- PRINT SUPPORT
//extension CategoriesSummaryView {
//    
//    // MARK: --- PrintToolbarItem
//    private var printToolbarItem: some ToolbarContent {
//        ToolbarItem(placement: .automatic) {
//            Button {
//                printCategoriesSummary()
//            } label: {
//                Label("Print Summary", systemImage: "printer")
//            }
//        }
//    }
//
//    // MARK: - CategoryPrintRow
//    fileprivate struct CategoryPrintRow: Identifiable {
//        let id: Int32
//        let name: String
//        let total: Decimal
//        
//        var totalString: String {
//            String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
//        }
//    }
//    
//    // MARK: --- PrintCategoriesSummary
//    func printCategoriesSummary() {
//        #if os(macOS)
//        DispatchQueue.main.async {
//            // Use the same categoryRows we show on-screen
//            let rows = categoryRows
//
//            // Compute overall totals from transactions
//            var total: Decimal = 0
//            var totalCR: Decimal = 0
//            var totalDR: Decimal = 0
//            for tx in transactions {
//                let amount = tx.txAmount
////                let amount = tx.totalAmountInGBP
//                total += amount
//                // We are storing a +ve number for money going out - a Debit
//                if amount < 0 { totalCR += amount }
//                else if amount > 0 { totalDR += amount }
//            }
//
//            // Reconciliation info
//            let reconciliation: Reconciliation? = {
//                if let recID = appState.selectedReconciliationID,
//                   let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
//                    return rec
//                }
//                return nil
//            }()
//
//            var startBalance: Decimal = 0
//            var endBalance: Decimal = 0
//            if let rec = reconciliation {
//                startBalance = rec.previousEndingBalance
//                endBalance = startBalance - total
//            }
//
//            // Build report text
//            let report = NSMutableString()
//            report.append("Category Summary Report")
//            if let rec = reconciliation { report.append(" — \(rec.paymentMethod.description)\n") }
//            else { report.append("\n") }
//
//            if let rec = reconciliation {
//                let period = "\(rec.periodMonth)/\(rec.periodYear)"
//                let statementDate = rec.statementDate?.formatted(date: .numeric, time: .omitted) ?? "-"
//                let closed = rec.closed ? "Closed" : "Open"
//                report.append("\(period) | \(statementDate) | \(closed)\n\n")
//            } else { report.append("No reconciliation found\n\n") }
//
//            report.append(String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString))
//            report.append(String(repeating: "-", count: 46) + "\n")
//
//            for row in rows {
//                let paddedName = row.category.description.padding(toLength: 30, withPad: " ", startingAt: 0)
//                let totalStr = row.totalString
//                let paddedTotal = String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr
//                report.append("\(paddedName)\(paddedTotal)\n")
//            }
//
//            report.append("\n" + String(repeating: "-", count: 46) + "\n")
//            func formatLine(label: String, amount: Decimal) -> String {
//                let amountStr = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
//                let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
//                let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
//                return "\(paddedLabel)\(paddedAmount)\n"
//            }
//
//            report.append(formatLine(label: "Starting Balance", amount: startBalance))
//            report.append(formatLine(label: "Total CR", amount: totalCR))
//            report.append(formatLine(label: "Total DR", amount: totalDR))
//            report.append(formatLine(label: "Net Total", amount: total))
//            report.append(formatLine(label: "Ending Balance", amount: endBalance))
//
//            // Display report in NSTextView
//            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 700))
//            textView.string = report as String
//            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
//            textView.isEditable = false
//            textView.sizeToFit()
//            textView.isHorizontallyResizable = false
//            textView.isVerticallyResizable = true
//
//            let printOp = NSPrintOperation(view: textView)
//            printOp.showsPrintPanel = true
//            printOp.showsProgressPanel = true
//            printOp.run()
//        }
//        #endif
//    }
//}
