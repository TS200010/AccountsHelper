import SwiftUI
import CoreData


// MARK: - CategoryRow Wrapper
fileprivate struct CategoryRow: Identifiable, Hashable {
    let category: Category
    let total: Decimal
    let transactionIDs: [NSManagedObjectID]
    
    var id: Int32 { category.id } // stable ID for selection
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}


// MARK: --- CategoriesSummaryView
struct CategoriesSummaryView: View {
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appStateOptional: AppState?
    
    // Single selection
    @State private var selectedCategoryID: Int32?
    
    init(predicate: NSPredicate? = nil, isPrinting: Bool = false) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    
    // MARK: --- CategoryRows
    fileprivate var categoryRows: [CategoryRow] {
        let predicate = transactions.nsPredicate ?? NSPredicate(value: true)
        let totals = viewContext.categoryTotals(for: predicate)

        return Category.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { category in
                CategoryRow(category: category, total: totals[category] ?? 0, transactionIDs: [])
            }
    }
    
    
    // MARK: --- CategoriesTable
    private var categoriesTable: some View {
        Table(categoryRows, selection: $selectedCategoryID) {
            TableColumn("Category") { row in
                categoryCell(for: row)
            }
            TableColumn("Total") { row in
                Text(row.totalString)
            }
        }
        .onChange(of: selectedCategoryID) { newValue in
            if let id = newValue,
               let row = categoryRows.first(where: { $0.id == id }) {
                appStateOptional?.selectedInspectorTransactionIDs = row.transactionIDs
                appStateOptional?.selectedInspectorView = .viewCategoryBreakdown
            } else {
                appStateOptional?.selectedInspectorTransactionIDs = []
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    
    // MARK: --- Category Cell (with Context Menu)
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
                appStateOptional?.pushCentralView(.browseTransactions( predicate ) )
            }
        }
    }
    
    
    // MARK: --- Totals (Precompute totals as formatted strings)
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
    

    // MARK: --- Body
    var body: some View {

        VStack(alignment: .leading ) {
            HStack ( spacing: 40) {
                    Text("Total: \(totals.total) GBP")
                    Text("Total CRs: \(totals.totalCR) GBP")
                    Text("Total DRs: \(totals.totalDR) GBP")
                }

            .padding( .horizontal, 10 )
            
            categoriesTable
                .navigationTitle("Transactions Summary")
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    printCategoriesSummary()
                } label: {
                    Label("Print Summary", systemImage: "printer")
                }
            }
        }
    }
}


// MARK: --- PRINT SUPPORT

// MARK: --- CategoryPrintRow
struct CategoryPrintRow: Identifiable {
    let id: Int32
    let name: String
    let total: Decimal
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}


extension CategoriesSummaryView {
    
    // MARK: --- PrintCategoriesSummary
    func printCategoriesSummary() {
        DispatchQueue.main.async {
            // 1. Prepare data
            let predicate = transactions.nsPredicate ?? NSPredicate(value: true)
            let totalsDecimal = viewContext.categoryTotals(for: predicate)
            
            let rows = Category.allCases
                .sorted { $0.rawValue < $1.rawValue }
                .map { category in
                    CategoryPrintRow(
                        id: category.id,
                        name: category.description,
                        total: totalsDecimal[category] ?? 0
                    )
                }
            
            var total: Decimal = 0
            var totalCR: Decimal = 0
            var totalDR: Decimal = 0
            for tx in transactions {
                let amount = tx.totalAmountInGBP
                total += amount
                if amount > 0 { totalCR += amount }
                else if amount < 0 { totalDR += amount }
            }
            
            // 2. Build report text
            // 2. Build simple report text
            var report = "Category Summary Report\n\n"
            report += String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString)
            report += String(repeating: "-", count: 46) + "\n"

            for row in rows {
                let name = row.name.prefix(30)
                let totalStr = String(format: "%.2f", NSDecimalNumber(decimal: row.total).doubleValue)
                
                // pad name on right, total on left for alignment
                let paddedName = name.padding(toLength: 30, withPad: " ", startingAt: 0)
                let paddedTotal = String(
                    repeating: " ",
                    count: max(0, 15 - totalStr.count)
                ) + totalStr
                
                report += "\(paddedName)\(paddedTotal)\n"
            }

            report += "\n"
            report += String(repeating: "-", count: 46) + "\n"

            func formatLine(label: String, amount: Decimal) -> String {
                let amountStr = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
                let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
                let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
                return "\(paddedLabel)\(paddedAmount)\n"
            }

            report += formatLine(label: "Total CR", amount: totalCR)
            report += formatLine(label: "Total DR", amount: totalDR)
            report += formatLine(label: "Net Total", amount: total)


        
            // 3. Create text view
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 700))
            textView.string = report
            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            textView.isEditable = false
            textView.sizeToFit()
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            
            // 4. Print operation
            let printOp = NSPrintOperation(view: textView)
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()
        }
    }
}
