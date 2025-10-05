//
//  CategoryPrintHelper.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 05/10/2025.
//

import SwiftUI
import PDFKit
import AppKit

struct CategoryPrintHelper {
    
    /// Generate a PDF data blob for a category summary
    /// - Parameters:
    ///   - categoryTotals: Dictionary of category -> total amounts
    ///   - accountingPeriod: String to show for the accounting period
    ///   - paymentMethod: Optional payment method to display as title
    /// - Returns: PDF Data or nil if failed
    static func generateCategoriesSummaryPDF(
        categoryTotals: [Category: Decimal],
        accountingPeriod: String,
        paymentMethod: String? = nil
    ) -> Data? {
        
        let pageWidth: CGFloat = 600
        let pageHeight: CGFloat = 800
        let margin: CGFloat = 40
        
        // Create a PDF document
        let pdfDocument = PDFDocument()
        
        // NSView to layout text
        let pdfView = NSView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        var yPosition = pageHeight - margin
        
        // Header: Accounting period left, date right
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date())
        
        let header = NSTextField(labelWithString: "Accounting Period: \(accountingPeriod)")
        header.font = NSFont.boldSystemFont(ofSize: 16)
        header.frame = NSRect(x: margin, y: yPosition - 20, width: pageWidth/2 - margin, height: 20)
        pdfView.addSubview(header)
        
        let dateLabel = NSTextField(labelWithString: dateString)
        dateLabel.alignment = .right
        dateLabel.font = NSFont.systemFont(ofSize: 14)
        dateLabel.frame = NSRect(x: pageWidth/2, y: yPosition - 20, width: pageWidth/2 - margin, height: 20)
        pdfView.addSubview(dateLabel)
        
        yPosition -= 40
        
        // Optional payment method title
        if let method = paymentMethod {
            let methodLabel = NSTextField(labelWithString: method)
            methodLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
            methodLabel.alignment = .center
            methodLabel.frame = NSRect(x: margin, y: yPosition - 20, width: pageWidth - 2 * margin, height: 20)
            pdfView.addSubview(methodLabel)
            yPosition -= 30
        }
        
        // Table headers
        let colCategory = NSTextField(labelWithString: "Category")
        colCategory.font = NSFont.boldSystemFont(ofSize: 14)
        colCategory.frame = NSRect(x: margin, y: yPosition, width: pageWidth/2, height: 20)
        pdfView.addSubview(colCategory)
        
        let colTotal = NSTextField(labelWithString: "Total")
        colTotal.font = NSFont.boldSystemFont(ofSize: 14)
        colTotal.alignment = .right
        colTotal.frame = NSRect(x: pageWidth/2, y: yPosition, width: pageWidth/2 - margin, height: 20)
        pdfView.addSubview(colTotal)
        
        yPosition -= 25
        
        // Iterate categories in enum order
        for category in Category.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            let total = categoryTotals[category] ?? 0
            
            let categoryLabel = NSTextField(labelWithString: category.description)
            categoryLabel.frame = NSRect(x: margin, y: yPosition, width: pageWidth/2, height: 20)
            pdfView.addSubview(categoryLabel)
            
            let totalString: String
            // Format JPY without decimals
//            if category.currencyCode == "JPY" {
//                totalString = total.string0f
//            } else {
//                totalString = total.string2f
//            }
            totalString = total.string2f
            
            let totalLabel = NSTextField(labelWithString: totalString)
            totalLabel.alignment = .right
            totalLabel.frame = NSRect(x: pageWidth/2, y: yPosition, width: pageWidth/2 - margin, height: 20)
            pdfView.addSubview(totalLabel)
            
            yPosition -= 20
        }
        
        // Render NSView into PDF
        guard let rep = pdfView.bitmapImageRepForCachingDisplay(in: pdfView.bounds) else { return nil }
        pdfView.cacheDisplay(in: pdfView.bounds, to: rep)
        let image = NSImage(size: pdfView.bounds.size)
        image.addRepresentation(rep)
        
        var pdfBounds = CGRect(origin: .zero, size: pdfView.bounds.size)
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pdfBounds, nil) else { return nil }
        
        context.beginPDFPage(nil)
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgImage, in: pdfBounds)
        }
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    /// Print the category summary using PDF
    /// - Parameters:
    ///   - categoryTotals: Dictionary of category -> total amounts
    ///   - accountingPeriod: String to display
    ///   - paymentMethod: Optional payment method title
    static func printCategoriesSummary(
        categoryTotals: [Category: Decimal],
        accountingPeriod: String,
        paymentMethod: String? = nil
    ) {
        guard let pdfData = generateCategoriesSummaryPDF(
            categoryTotals: categoryTotals,
            accountingPeriod: accountingPeriod,
            paymentMethod: paymentMethod
        ),
        let pdfDocument = PDFDocument(data: pdfData) else {
            print("Failed to generate PDF")
            return
        }
        
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.topMargin = 20
        printInfo.leftMargin = 20
        printInfo.rightMargin = 20
        printInfo.bottomMargin = 20
        

        
        let printView = PDFView(frame: NSRect(x: 0, y: 0, width: 600, height: 800))
        printView.document = pdfDocument
        printView.autoScales = true
        
        DispatchQueue.main.async {
            let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
            printOperation.showsPrintPanel = true
            printOperation.showsProgressPanel = true
            printOperation.run()
        }

    }
}
