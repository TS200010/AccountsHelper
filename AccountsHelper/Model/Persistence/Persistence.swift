//
//  Persistence.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import CoreData

/*
    ────────────────────────────────────────────────────────────────
    PersistenceController
    • Manages the Core Data stack (local + CloudKit)
    • Handles in-memory mode for testing
    • Observes remote iCloud Core Data changes
    • Initializes CloudKit schema when requested in DEBUG mode
    ────────────────────────────────────────────────────────────────
*/

final class PersistenceController {
    
    // MARK: --- Shared Singleton
    static let shared = PersistenceController()
    
    // MARK: --- Properties
    let container: NSPersistentCloudKitContainer
    private var remoteChangeObserver: NSObjectProtocol?
    
    // MARK: --- Initializer
    init(inMemory: Bool = false) {
        
        // Enable CoreData + CloudKit debugging
        UserDefaults.standard.set(true, forKey: "com.apple.CoreData.CloudKitDebug")
        
        // Create container with model name
        container = NSPersistentCloudKitContainer(name: "AccountsHelperModel")
        
        // Configure CloudKit environment
        if gUseLiveStore {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                    NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.ItMk.AccountsHelper.live"
                    )
            }
        } else {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                    NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.ItMk.AccountsHelper.dev"
                    )
            }
        }
        
        // Load persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("❌ Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Merge settings
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Observe iCloud remote changes
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification)
        }
        
        // Optional: Initialize CloudKit schema in DEBUG mode
        #if DEBUG
        if gUploadSchema {
            do {
                try container.initializeCloudKitSchema(options: [])
                print("✅ CloudKit schema initialized")
            } catch {
                print("❌ Failed to initialize CloudKit schema: \(error)")
            }
        }
        #endif
        
        // Optional: Log SQLite store path
        #if DEBUG
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            print("📁 CoreData SQLite file is at: \(storeURL.path)")
        }
        #endif
    }
    
    // MARK: --- Remote Change Handler
    private func handleRemoteChange(_ notification: Notification) {
        print("🔄 Remote change received — updating UI")
        let context = container.viewContext
        context.perform {
            NotificationCenter.default.post(
                name: Notification.Name("AccountsHelperRemoteChange"),
                object: nil
            )
        }
    }
    
    
    // MARK: --- Deinitializer
    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: --- TRANSACTION COPY FROM LIVE TO DEV
// MARK: --- ... CSV Export / Import for Transactions

extension PersistenceController {

    // MARK: - Export to CSV
    func exportTransactionsToCSV() -> Int {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        do {
            let transactions = try context.fetch(fetchRequest)
            guard !transactions.isEmpty else { return 0 }

            var csvText = "accountNumber,address,categoryCD,closed,commissionAmountCD,currencyCD,debitCreditCD,exchangeRateCD,explanation,extendedDetails,payee,payerCD,accountCD,reference,splitAmountCD,splitCategoryCD,timestamp,transactionDate,txAmountCD\n"

            let dateFormatter = ISO8601DateFormatter()

            for tx in transactions {
                let f: (Any?) -> String = { value in
                    if let date = value as? Date { return dateFormatter.string(from: date) }
                    if let b = value as? Bool { return b ? "true" : "false" }
                    if let s = value as? String { return s.replacingOccurrences(of: ",", with: " ") }
                    return "\(value ?? "")"
                }

                let fields: [String] = [
//                    f(tx.accountingPeriod),
                    f(tx.accountNumber),
                    f(tx.address),
                    f(tx.categoryCD),
                    f(tx.closed),
                    f(tx.commissionAmountCD),
                    f(tx.currencyCD),
                    f(tx.debitCreditCD),
                    f(tx.exchangeRateCD),
                    f(tx.explanation),
                    f(tx.extendedDetails),
                    f(tx.payee),
                    f(tx.payerCD),
                    f(tx.accountCD),
                    f(tx.reference),
                    f(tx.splitAmountCD),
                    f(tx.splitCategoryCD),
                    f(tx.timestamp),
                    f(tx.transactionDate),
                    f(tx.txAmountCD)
                ]

                csvText += fields.joined(separator: ",") + "\n"
            }


            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("TransactionsExport.csv")

            try csvText.write(to: url, atomically: true, encoding: .utf8)
            print("✅ Exported \(transactions.count) transactions to \(url.path)")
            return transactions.count

        } catch {
            print("❌ Export failed: \(error)")
            return 0
        }
    }

    // MARK: - Import from CSV
    func importTransactionsFromCSV() -> Int {
        let context = container.viewContext

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TransactionsExport.csv")

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ CSV file not found at \(url.path)")
            return 0
        }

        do {
            let csvData = try String(contentsOf: url, encoding: .utf8)
            var lines = csvData.components(separatedBy: "\n")
            guard lines.count > 1 else { return 0 }
            lines.removeFirst() // remove header

            let dateFormatter = ISO8601DateFormatter()
            var count = 0

            for line in lines where !line.isEmpty {
                let components = line.components(separatedBy: ",")
                guard components.count >= 20 else { continue }

                let tx = Transaction(context: context)
//                tx.accountingPeriod = components[0]
                tx.accountNumber = components[1]
                tx.address = components[2]
                tx.categoryCD = Int32(components[3]) ?? 0
                tx.closed = Bool(components[4]) ?? false
                tx.commissionAmountCD = Int32(components[5]) ?? 0
                tx.currencyCD = Int32(components[6]) ?? 0
                tx.debitCreditCD = Int32(components[7]) ?? 0
                tx.exchangeRateCD = Int32(components[8]) ?? 0
                tx.explanation = components[9]
                tx.extendedDetails = components[10]
                tx.payee = components[11]
                tx.payerCD = Int32(components[12]) ?? 0
                tx.accountCD = Int32(components[13]) ?? 0
                tx.reference = components[14]
                tx.splitAmountCD = Int32(components[15]) ?? 0
                tx.splitCategoryCD = Int32(components[16]) ?? 0
                tx.timestamp = dateFormatter.date(from: components[17])
                tx.transactionDate = dateFormatter.date(from: components[18])
                tx.txAmountCD = Int32(components[19]) ?? 0

                count += 1
            }

            try context.save()
            print("✅ Imported \(count) transactions from CSV")
            return count

        } catch {
            print("❌ Import failed: \(error)")
            return 0
        }
    }
}

