//
//  CSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 01/10/2025.
//

import Foundation

protocol CSVImporter {
    static var displayName: String { get }
    static var paymentMethod: PaymentMethod { get }
    static func parseCSV(csvData: String) -> [[String]]
    static func parseCSVToTransactionStruct(fileURL: URL) -> [TransactionStruct]
    static func findMergeCandidateInSnapshot(newTx: TransactionStruct, snapshot: [Transaction]) -> Transaction?
}

extension CSVImporter {
    
    // MARK: - CSV Parser (handles quotes and multi-line fields)
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
