//
//  VISAPNGImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 01/10/2025.
//

import Foundation
import CoreData
import Vision
import AppKit   // macOS only (for NSImage)

class VISAPNGImporter: CSVImporter {
    
    static var displayName: String = "VISA PNG Importer"
    
    static var paymentMethod: PaymentMethod = .VISA
    
    // MARK: - Parse PNG Screenshot (OCR → CSV)
    static func parsePNGToTransactionStruct(fileURL: URL, completion: @escaping ([TransactionStruct]) -> Void) {
        guard let image = NSImage(contentsOf: fileURL) else {
            print("Could not load PNG at \(fileURL.path)")
            completion([])
            return
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to create CGImage from NSImage")
            completion([])
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No OCR results")
                completion([])
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: "\n")
            
            print("OCR Extracted Text:\n\(fullText)")
            
            let transactions = parseCSVTextToTransactions(fullText)
            completion(transactions)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("OCR failed: \(error)")
            completion([])
        }
    }
    
    // MARK: - Helper: Reuse CSV pipeline for OCR text
    private static func parseCSVTextToTransactions(_ text: String) -> [TransactionStruct] {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("visa_ocr.csv")
        do {
            try text.write(to: tempFile, atomically: true, encoding: .utf8)
            return parseCSVToTransactionStruct(fileURL: tempFile)
        } catch {
            print("Failed to save OCR text to temp file: \(error)")
            return []
        }
    }
    
    // MARK: - Parse CSV text file (reused by OCR pipeline)
    static func parseCSVToTransactionStruct(fileURL: URL) -> [TransactionStruct] {
        var transactions: [TransactionStruct] = []
        var accountTemp: String = ""
        
        print("Starting VISA CSV parse: \(fileURL.path)")
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }
            
            let matcher = CategoryMatcher(context: PersistenceController.shared.container.viewContext)
            
            for row in rows.dropFirst() {
                guard row.count == headers.count else { continue }
                
                var tx = TransactionStruct()
                
                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    switch header.lowercased() {
                    case "transaction date", "date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        tx.transactionDate = formatter.date(from: value)
                        
                    case "transaction type", "type":
                        tx.explanation = value
                        
                    case "sort code":
                        accountTemp = value
                        
                    case "account number":
                        accountTemp += " " + value
                        
                    case "transaction description", "description", "details":
                        tx.payee = value
                        tx.category = matcher.matchCategory(for: value)
                        
                    case "debit amount":
                        if let debit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), debit > 0 {
                            tx.txAmount = debit
                            tx.debitCredit = .DR
                        }
                        
                    case "credit amount":
                        if let credit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), credit > 0 {
                            tx.txAmount = credit
                            tx.debitCredit = .CR
                        }
                        
                    case "amount":
                        // For formats with a single signed Amount column
                        if let amt = Decimal(string: value.replacingOccurrences(of: ",", with: "")) {
                            tx.txAmount = amt.magnitude
                            tx.debitCredit = amt < 0 ? .DR : .CR
                        }
                        
                    case "balance":
                        break   // Ignore balances
                        
                    default:
                        break
                    }
                }
                
                tx.paymentMethod = paymentMethod
                tx.accountNumber = accountTemp
                tx.currency = .GBP
                tx.exchangeRate = 1
                
                transactions.append(tx)
            }
            
        } catch {
            print("Failed to read VISA CSV: \(error)")
        }
        
        return transactions
    }
    
    // MARK: - CSV Parser
    static func parseCSV(csvData: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in csvData {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (char == "\n" || char == "\r\n") && !insideQuotes {
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        
        // Trim trailing empty fields from header row
        if var header = rows.first {
            while let last = header.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
                header.removeLast()
            }
            rows[0] = header
        }
        
        return rows
    }
}
