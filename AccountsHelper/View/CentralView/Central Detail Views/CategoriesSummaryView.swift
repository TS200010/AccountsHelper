import SwiftUI
import CoreData
import PDFKit

struct TransactionsInspectorView: View {
    var body: some View {
        Text("Transactions Inspector View")
    }
}

// MARK: --- Extension to sum transactions including splits
extension Array where Element == Transaction {
    func sumByCategoryIncludingSplitsInGBP() -> [Category: Decimal] {
        var result: [Category: Decimal] = [:]
        
        for category in Category.allCases {
            result[category] = 0
        }
        
        for tx in self {
            let splitAmt = tx.splitAmountInGBP
            if !splitAmt.isNaN {
                result[tx.splitCategory, default: 0] += splitAmt
            } else {
                print("⚠️ NaN splitAmountInGBP in tx:", tx)
            }

            let remainderAmt = tx.splitRemainderAmountInGBP
            if !remainderAmt.isNaN {
                result[tx.splitRemainderCategory, default: 0] += remainderAmt
            } else {
                print("⚠️ NaN splitRemainderAmountInGBP in tx:", tx)
            }
        }
        
        return result
    }
}

extension Decimal {
    var string2f: String {
        String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }
}

extension Decimal {
    var string0f: String {
        String(format: "%.0f", NSDecimalNumber(decimal: self).doubleValue)
    }
}


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
    @Environment(AppState.self) var appState
    
    // Single selection
    @State private var selectedCategoryID: Int32?
    
    init(predicate: NSPredicate? = nil) {
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
                appState.selectedInspectorTransactionIDs = row.transactionIDs
                appState.selectedInspectorView = .viewCategoryBreakdown
            } else {
                appState.selectedInspectorTransactionIDs = []
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
                    appState.pushCentralView(.browseTransactions( predicate ) )
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
    
    // MARK: --- Print Support
//    fileprivate func generateCategoriesSummaryPDF(categoryRows: [CategoryRow], accountingPeriod: String) -> Data? {
//        
//        let pageWidth: CGFloat = 600
//        let pageHeight: CGFloat = 800
//        let margin: CGFloat = 40
//        
//        // Create a PDF document
//        let pdfDocument = PDFDocument()
//        
//        // Start a PDF page
//        let pdfPage = PDFPage()
//        let pdfView = NSView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
//        
//        var yPosition = pageHeight - margin
//        
//        // Header: Accounting period left, date right
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .short
//        dateFormatter.timeStyle = .short
//        let dateString = dateFormatter.string(from: Date())
//        
//        let header = NSTextField(labelWithString: accountingPeriod)
//        header.font = NSFont.boldSystemFont(ofSize: 16)
//        header.frame = NSRect(x: margin, y: yPosition - 20, width: pageWidth/2 - margin, height: 20)
//        pdfView.addSubview(header)
//        
//        let dateLabel = NSTextField(labelWithString: dateString)
//        dateLabel.alignment = .right
//        dateLabel.font = NSFont.systemFont(ofSize: 14)
//        dateLabel.frame = NSRect(x: pageWidth/2, y: yPosition - 20, width: pageWidth/2 - margin, height: 20)
//        pdfView.addSubview(dateLabel)
//        
//        yPosition -= 40
//        
//        // Table headers
//        let colCategory = NSTextField(labelWithString: "Category")
//        colCategory.font = NSFont.boldSystemFont(ofSize: 14)
//        colCategory.frame = NSRect(x: margin, y: yPosition, width: pageWidth/2, height: 20)
//        pdfView.addSubview(colCategory)
//        
//        let colTotal = NSTextField(labelWithString: "Total")
//        colTotal.font = NSFont.boldSystemFont(ofSize: 14)
//        colTotal.alignment = .right
//        colTotal.frame = NSRect(x: pageWidth/2, y: yPosition, width: pageWidth/2 - margin, height: 20)
//        pdfView.addSubview(colTotal)
//        
//        yPosition -= 25
//        
//        // Iterate categories in enum order
//        for row in categoryRows {
//            let categoryLabel = NSTextField(labelWithString: row.category.description)
//            categoryLabel.frame = NSRect(x: margin, y: yPosition, width: pageWidth/2, height: 20)
//            pdfView.addSubview(categoryLabel)
//            
//            let totalString: String
//            // TODO: Tweak JPY formatting
////            if row.category.currencyCode == "JPY" {
////                totalString = row.total.string0f
////            } else {
////                totalString = row.total.string2f
////            }
//            totalString = row.total.string2f
//            
//            let totalLabel = NSTextField(labelWithString: totalString)
//            totalLabel.alignment = .right
//            totalLabel.frame = NSRect(x: pageWidth/2, y: yPosition, width: pageWidth/2 - margin, height: 20)
//            pdfView.addSubview(totalLabel)
//            
//            yPosition -= 20
//        }
//        
//        // Render NSView into PDF page
//        let rep = pdfView.bitmapImageRepForCachingDisplay(in: pdfView.bounds)!
//        pdfView.cacheDisplay(in: pdfView.bounds, to: rep)
//        
//        let image = NSImage(size: pdfView.bounds.size)
//        image.addRepresentation(rep)
//        
//        let pdfBounds = CGRect(origin: .zero, size: pdfView.bounds.size)
//        let pdfData = NSMutableData()
//        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
//        var mediaBox = pdfBounds
//        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
//        
//        context.beginPDFPage(nil)
//        context.draw(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, in: pdfBounds)
//        context.endPDFPage()
//        context.closePDF()
//        
//        return pdfData as Data
//    }
    
//    fileprivate func printCategoriesSummary(categoryRows: [CategoryRow], accountingPeriod: String) {
//        
//        guard let pdfData = generateCategoriesSummaryPDF(categoryRows: categoryRows, accountingPeriod: accountingPeriod),
//              let pdfDocument = PDFDocument(data: pdfData) else {
//            print("Failed to generate PDF")
//            return
//        }
//        
//        let printInfo = NSPrintInfo.shared
//        printInfo.horizontalPagination = .automatic
//        printInfo.verticalPagination = .automatic
//        printInfo.topMargin = 20
//        printInfo.leftMargin = 20
//        printInfo.rightMargin = 20
//        printInfo.bottomMargin = 20
//        
//        let printView = PDFView(frame: .zero)
//        printView.document = pdfDocument
//        printView.autoScales = true
//        
//        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
//        printOperation.showsPrintPanel = true   // show standard print dialog
//        printOperation.showsProgressPanel = true
//        printOperation.run()
//    }
    
    
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
    }
}
