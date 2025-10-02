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

class VISAPNGImporter: TxImporter {

    static var displayName: String = "VISA PNG Importer"
    static var paymentMethod: PaymentMethod = .VISA
    static var importType: ImportType = .png

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @Sendable (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction] {

        var createdTransactions: [Transaction] = []

        // --- Temporary context exactly like AMEX ---
        let tempContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        tempContext.parent = context

        // --- Convert PNG → CSV-like temp file ---
        let csvFileURL: URL = await withCheckedContinuation { continuation in
            parsePNGToCSV(fileURL: fileURL) { tempCSV in
                continuation.resume(returning: tempCSV)
            }
        }

        // --- Use AMEXCSVImporter logic for parsing CSV into transactions ---
        do {
            let csvData = try String(contentsOf: csvFileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            print(rows)
            guard let headers = rows.first else { return [] }

            // Fetch existing transactions from main context
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            let matcher = CategoryMatcher(context: tempContext)

            for row in rows.dropFirst() {
                guard row.count >= 5 else { continue }

                let tx = Transaction(context: tempContext)

                // --- Map fields ---
                tx.accountNumber = row[0].isEmpty ? "0000" : row[0]

                // Transaction date (default year = current)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMMM yyyy"
                let year = Calendar.current.component(.year, from: Date())
                if let date = formatter.date(from: "\(row[1]) \(year)") {
                    tx.transactionDate = date
                }

                // Date entered → explanation
                tx.explanation = "Date entered: \(row[2])"

                // Payee
                let payeeFields = row[3..<(row.count - 2)]
                tx.payee = payeeFields.joined(separator: " ")

                // Amount
                if let amount = Decimal(string: row[row.count - 2].replacingOccurrences(of: ",", with: "")) {
                    tx.txAmount = amount
                }

                // CR/DR
                let lastField = row.last?.uppercased() ?? ""
                tx.debitCredit = lastField == "CR" ? .CR : .DR

                // Currency
                tx.currency = .GBP
                tx.exchangeRate = 1

                tx.paymentMethod = paymentMethod

                // --- Merge checking ---
                if let existing = Self.findMergeCandidateInSnapshot(newTx: tx, snapshot: createdTransactions + existingSnapshot) {

                    if existing.comparableFieldsRepresentation() == tx.comparableFieldsRepresentation() {
                        tempContext.delete(tx)
                        continue
                    }

                    let mergedTx = await mergeHandler(existing, tx)
                    if !createdTransactions.contains(mergedTx) {
                        createdTransactions.append(mergedTx)
                    }
                    tempContext.delete(tx)

                } else {
                    createdTransactions.append(tx)
                }
            }

            try tempContext.save()

        } catch {
            print("Failed to parse VISA CSV: \(error)")
        }

        return createdTransactions
    }

    // MARK: - PNG → CSV front-end (frozen logic)
    static func parsePNGToCSV(fileURL: URL, completion: @escaping (URL) -> Void) {
        guard let image = NSImage(contentsOf: fileURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(URL(fileURLWithPath: "/dev/null"))
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                completion(URL(fileURLWithPath: "/dev/null"))
                return
            }

            // --- FROZEN LOGIC: Group OCR observations into rows by Y coordinate ---
            let sortedObs = observations.sorted { $0.boundingBox.minY > $1.boundingBox.minY }

            var rows: [[VNRecognizedTextObservation]] = []
            let yThreshold: CGFloat = 0.02

            for obs in sortedObs {
                if let lastRow = rows.last,
                   let lastObs = lastRow.first,
                   abs(obs.boundingBox.minY - lastObs.boundingBox.minY) < yThreshold {
                    rows[rows.count - 1].append(obs)
                } else {
                    rows.append([obs])
                }
            }

            // --- Convert each row of observations into normalized fields ---
            var csvRows: [[String]] = []

            for rowObs in rows {
                let rowStrings = rowObs.compactMap { $0.topCandidates(1).first?.string }

                guard !rowStrings.isEmpty else { continue }

                var fields: [String] = []

                // Field 0: Card Ending
                let first = rowStrings[0].trimmingCharacters(in: .whitespacesAndNewlines)
                fields.append(first.isEmpty ? "0000" : first)

                // Field 1: Transaction Date
                let txDate = rowStrings.count > 1 ? rowStrings[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                fields.append(txDate)

                // Field 2: Date Entered
                let dateEntered = rowStrings.count > 2 ? rowStrings[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                fields.append(dateEntered)

                // Fields 3 .. N-2 → Payee / Description
                let payeeStart = 3
                let payeeEnd = max(rowStrings.count - 2, payeeStart)
                let payee = payeeStart < payeeEnd ? rowStrings[payeeStart..<payeeEnd].joined(separator: " ") : ""
                fields.append(payee)

                // Second-to-last → Amount
                let amount = rowStrings.count >= 2 ? rowStrings[rowStrings.count - 2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                fields.append(amount)

                // Last → CR/DR
                let lastField = rowStrings.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                fields.append(lastField)

                csvRows.append(fields)
            }

            // --- Write CSV to temporary file ---
            let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("visa_ocr.csv")
            var csvText = ""
            for row in csvRows {
                csvText += row.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            }

            do {
                try csvText.write(to: tempFile, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write temp CSV: \(error)")
            }

            completion(tempFile)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.customWords = ["GB"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(URL(fileURLWithPath: "/dev/null"))
        }
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

        if var header = rows.first {
            while let last = header.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
                header.removeLast()
            }
            rows[0] = header
        }

        return rows
    }
}
