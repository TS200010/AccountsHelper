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
//    @Environment(AppState.self) var appState
    @Environment(AppState.self) private var appStateOptional: AppState?

    
    var isPrinting: Bool = false
    
    // Single selection
    @State private var selectedCategoryID: Int32?
    
//    init(predicate: NSPredicate? = nil) {
//        _transactions = FetchRequest(
//            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
//            predicate: predicate
//        )
//    }
    init(predicate: NSPredicate? = nil, isPrinting: Bool = false) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
        self.isPrinting = isPrinting
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
                if !isPrinting {
                    appStateOptional?.selectedInspectorTransactionIDs = row.transactionIDs
                    appStateOptional?.selectedInspectorView = .viewCategoryBreakdown
                }
            } else {
                if !isPrinting {
                    appStateOptional?.selectedInspectorTransactionIDs = []
                }
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
            if !isPrinting {
                Button("Transactions") {
                    let predicate = NSPredicate(format: "categoryCD == %d", row.id)
                        appStateOptional?.pushCentralView(.browseTransactions( predicate ) )
                }
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
//                    printHelloWorld()
                    printSelf()
                } label: {
                    Label("Print Summary", systemImage: "printer")
                }
            }
        }
    }
}

// MARK: --- PRINT SUPPORT

//struct CategoriesPrintView: View {
//    let rows: [CategoryPrintRow]
//    let totals: (total: Decimal, totalCR: Decimal, totalDR: Decimal)
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Transactions Summary")
//                .font(.title)
//                .padding(.bottom, 10)
//            
//            HStack(spacing: 40) {
//                Text("Total: \(totals.total.string2f) GBP")
//                Text("Total CRs: \(totals.totalCR.string2f) GBP")
//                Text("Total DRs: \(totals.totalDR.string2f) GBP")
//            }
//            .padding(.bottom, 10)
//            
//            VStack(alignment: .leading, spacing: 5) {
//                ForEach(rows) { row in
//                    HStack {
//                        Text(row.name)
//                        Spacer()
//                        Text(row.totalString)
//                    }
//                }
//            }
//            .padding(.top, 5)
//        }
//        .padding()
//        .frame(width: 595, height: 842) // A4
//    }
//}

struct CategoryPrintRow: Identifiable {
    let id: Int32
    let name: String
    let total: Decimal
    
    var totalString: String {
        String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
}

struct CategoriesPrintView: View {
    let rows: [CategoryPrintRow]
    let totals: (total: Decimal, totalCR: Decimal, totalDR: Decimal)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transactions Summary")
                .font(.system(size: 14, weight: .bold))
            
            HStack(spacing: 20) {
                Text("Total: \(totals.total.string2f) GBP")
                    .font(.system(size: 12))
                Text("Total CRs: \(totals.totalCR.string2f) GBP")
                    .font(.system(size: 12))
                Text("Total DRs: \(totals.totalDR.string2f) GBP")
                    .font(.system(size: 12))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(rows) { row in
                    HStack {
                        Text(row.name)
                            .font(.system(size: 10))
                        Spacer()
                        Text(row.totalString)
                            .font(.system(size: 10))
                    }
                }
            }
            
            Spacer() // push content to top
        }
        .padding(5)
        .frame(width: 595, height: 842, alignment: .topLeading) // A4
    }
}



//extension CategoriesSummaryView {
//
//    func printSelf() {
//        DispatchQueue.main.async {
//            // 1. Precompute data
//            let predicate = transactions.nsPredicate ?? NSPredicate(value: true)
//            let totalsDecimal = viewContext.categoryTotals(for: predicate)
//            
//            let rows = Category.allCases
//                .sorted { $0.rawValue < $1.rawValue }
//                .map { category in
//                    CategoryPrintRow(
//                        id: category.id,
//                        name: category.description,
//                        total: totalsDecimal[category] ?? 0
//                    )
//                }
//            
//            var total: Decimal = 0
//            var totalCR: Decimal = 0
//            var totalDR: Decimal = 0
//            for tx in transactions {
//                let amount = tx.totalAmountInGBP
//                total += amount
//                if amount > 0 { totalCR += amount }
//                else if amount < 0 { totalDR += amount }
//            }
//            
//            let printView = CategoriesPrintView(
//                rows: rows,
//                totals: (total: total, totalCR: totalCR, totalDR: totalDR)
//            )
//            
//            // 2. Hosting view with large height to include all content
//            let hostingView = NSHostingView(rootView: printView)
//            hostingView.frame = CGRect(x: 0, y: 0, width: 595, height: 2000) // tall frame
//            hostingView.layoutSubtreeIfNeeded()
//            
//            let contentSize = hostingView.fittingSize
//            let a4Size = CGSize(width: 595, height: 842) // A4 points
//            
//            // 3. Compute scale to fit A4
//            let scale = min(a4Size.width / contentSize.width,
//                            a4Size.height / contentSize.height)
//            
//            // 4. Render PDF
//            var mediaBox = CGRect(origin: .zero, size: a4Size)
//            let pdfData = NSMutableData()
//            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
//                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
//            else { return }
//            
//            pdfContext.beginPDFPage(nil)
//            pdfContext.saveGState()
//            
//            // Flip vertically
//            pdfContext.translateBy(x: 0, y: a4Size.height)
//            pdfContext.scaleBy(x: 1.0, y: -1.0)
//            
//            // Center and scale content to fit exactly
//            let offsetX = (a4Size.width - contentSize.width * scale) / 2
//            let offsetY = (a4Size.height - contentSize.height * scale) / 2
//            pdfContext.translateBy(x: offsetX, y: offsetY)
//            pdfContext.scaleBy(x: scale, y: scale)
//            
//            // Render the hosting view
//            hostingView.layer?.render(in: pdfContext)
//            
//            pdfContext.restoreGState()
//            pdfContext.endPDFPage()
//            pdfContext.closePDF()
//            
//            // 5. Print PDF
//            guard let document = PDFDocument(data: pdfData as Data) else { return }
//            let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: a4Size.width, height: a4Size.height))
//            pdfView.document = document
//            
//            let printOp = NSPrintOperation(view: pdfView)
//            printOp.showsPrintPanel = true
//            printOp.showsProgressPanel = true
//            printOp.run()
//        }
//    }
//}

import AppKit
import PDFKit

extension CategoriesSummaryView {

    func printHelloWorld() {
        DispatchQueue.main.async {
            let a4Size = CGSize(width: 595, height: 842)
            let margin: CGFloat = 50
            let rowHeight: CGFloat = 24
            let colWidths: [CGFloat] = [200, 150, 100] // 3 columns

            // Sample data
            let headers = ["Category", "Count", "Total GBP"]
            let rows = [
                ["Food", "5", "123.45"],
                ["Transport", "3", "67.80"],
                ["Entertainment", "2", "45.00"]
            ]

            // 1. Create PDF data buffer
            let pdfData = NSMutableData()
            var mediaBox = CGRect(origin: .zero, size: a4Size)

            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                print("Failed to create PDF context")
                return
            }

            // 2. Begin PDF page
            context.beginPDFPage(nil)

            // 3. Set NSGraphicsContext for NSString drawing
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext

            let font = NSFont.systemFont(ofSize: 14)
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]

            var yPos = a4Size.height - margin

            // Draw table headers
            var xPos = margin
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: attributes)
                xPos += colWidths[i]
            }
            yPos -= rowHeight

            // Draw table rows
            for row in rows {
                xPos = margin
                for (i, cell) in row.enumerated() {
                    cell.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: attributes)
                    xPos += colWidths[i]
                }
                yPos -= rowHeight
            }

            // 4. Clean up
            NSGraphicsContext.current = nil
            context.endPDFPage()
            context.closePDF()

            // 5. Load PDFDocument
            guard let document = PDFDocument(data: pdfData as Data) else { return }

            // 6. Print
            let printInfo = NSPrintInfo.shared
            if #available(macOS 12.0, *) {
                if let printOp = document.printOperation(
                    for: printInfo,
                    scalingMode: .pageScaleNone,
                    autoRotate: true
                ) {
                    printOp.showsPrintPanel = true
                    printOp.showsProgressPanel = true
                    printOp.run()
                }
            } else {
                let pdfView = PDFView(frame: NSRect(origin: .zero, size: a4Size))
                pdfView.document = document
                let printOp = NSPrintOperation(view: pdfView)
                printOp.showsPrintPanel = true
                printOp.showsProgressPanel = true
                printOp.run()
            }
        }
    }
}

import AppKit
import PDFKit
import SwiftUI

extension CategoriesSummaryView {

    func printSelfNotScaled() {
        DispatchQueue.main.async {
            let a4Size = CGSize(width: 595, height: 842) // A4 points
            let margin: CGFloat = 50
            let rowHeight: CGFloat = 20
            let font = NSFont.systemFont(ofSize: 12)
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]

            // 1. Precompute data
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

            // 2. Create PDF context
            let pdfData = NSMutableData()
            var mediaBox = CGRect(origin: .zero, size: a4Size)

            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }

            context.beginPDFPage(nil)

            // 3. Set NSGraphicsContext for drawing
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext

            var yPos = a4Size.height - margin

            // Draw Title
            let title = "Transactions Summary" as NSString
            title.draw(at: CGPoint(x: margin, y: yPos), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 16)])
            yPos -= rowHeight * 2

            // Draw table headers
            let colWidths: [CGFloat] = [300, 100] // Category, Total
            let headers = ["Category", "Total GBP"]
            var xPos = margin
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 12)])
                xPos += colWidths[i]
            }
            yPos -= rowHeight

            // Draw table rows
            for row in rows {
                xPos = margin
                let cells = [row.name, row.totalString]
                for (i, cell) in cells.enumerated() {
                    cell.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: attributes)
                    xPos += colWidths[i]
                }
                yPos -= rowHeight
            }

            yPos -= rowHeight

            // Draw totals
            let totalsText = "Total: \(total.string2f)   CR: \(totalCR.string2f)   DR: \(totalDR.string2f)" as NSString
            totalsText.draw(at: CGPoint(x: margin, y: yPos), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 12)])

            NSGraphicsContext.current = nil
            context.endPDFPage()
            context.closePDF()

            // 4. Load PDFDocument and print
            guard let document = PDFDocument(data: pdfData as Data) else { return }
            let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: a4Size.width, height: a4Size.height))
            pdfView.document = document

            let printOp = NSPrintOperation(view: pdfView)
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()
        }
    }
}



import AppKit
import PDFKit
import SwiftUI

extension CategoriesSummaryView {

    func printSelfBestChatGPTSoFar() {
        DispatchQueue.main.async {
            let a4Size = CGSize(width: 595, height: 842) // A4 points
            let margin: CGFloat = 40
            let rowHeight: CGFloat = 14
            let fontSize: CGFloat = 10

            // 1. Precompute data
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

            // 2. Create PDF context
            let pdfData = NSMutableData()
            var mediaBox = CGRect(origin: .zero, size: a4Size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }

            context.beginPDFPage(nil)
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext

            // 3. Start drawing top-aligned
            context.saveGState()
            var yPos = margin

            // Draw Title
            let title = "Transactions Summary" as NSString
            title.draw(at: CGPoint(x: margin, y: yPos), withAttributes: [.font: NSFont.boldSystemFont(ofSize: fontSize + 2),
                                                                        .foregroundColor: NSColor.black])
            yPos += rowHeight * 2

            // Table headers
            let colWidths: [CGFloat] = [300, 100]
            let headers = ["Category", "Total GBP"]
            var xPos: CGFloat = margin
            let headerFont = NSFont.boldSystemFont(ofSize: fontSize)
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: [.font: headerFont, .foregroundColor: NSColor.black])
                xPos += colWidths[i]
            }
            yPos += rowHeight

            // Table rows
            let rowFont = NSFont.systemFont(ofSize: fontSize)
            let rowAttributes: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: NSColor.black]
            for row in rows {
                xPos = margin
                let cells = [row.name, row.totalString]
                for (i, cell) in cells.enumerated() {
                    cell.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: rowAttributes)
                    xPos += colWidths[i]
                }
                yPos += rowHeight
            }

            yPos += rowHeight / 2

            // Totals
            let totalsText = "Total: \(total.string2f)   CR: \(totalCR.string2f)   DR: \(totalDR.string2f)" as NSString
            totalsText.draw(at: CGPoint(x: margin, y: yPos), withAttributes: [.font: NSFont.boldSystemFont(ofSize: fontSize),
                                                                            .foregroundColor: NSColor.black])

            context.restoreGState()
            NSGraphicsContext.current = nil
            context.endPDFPage()
            context.closePDF()

            // 4. Print PDF
            guard let document = PDFDocument(data: pdfData as Data) else { return }
            let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: a4Size.width, height: a4Size.height))
            pdfView.document = document

            let printOp = NSPrintOperation(view: pdfView)
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()
        }
    }
}

extension CategoriesSummaryView {
    func printSelf() {
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
            var report = "Category Summary Report\n\n"
            report += String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString)
            report += String(repeating: "-", count: 46) + "\n"

            for row in rows {
                let name = row.name.prefix(30)
                let totalStr = String(format: "%.2f", NSDecimalNumber(decimal: row.total).doubleValue)
                let paddedName = name.padding(toLength: 30, withPad: " ", startingAt: 0)
                let paddedTotal = totalStr.padding(toLength: 15, withPad: " ", startingAt: 0)
                report += "\(paddedName)\(paddedTotal)\n"
            }

            report += "\n"
            report += "----------------------------------------------\n"
            report += String(format: "%-30@ %15.2f\n", "Total CR" as NSString, NSDecimalNumber(decimal: totalCR).doubleValue)
            report += String(format: "%-30@ %15.2f\n", "Total DR" as NSString, NSDecimalNumber(decimal: totalDR).doubleValue)
            report += String(format: "%-30@ %15.2f\n", "Net Total" as NSString, NSDecimalNumber(decimal: total).doubleValue)

        
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
