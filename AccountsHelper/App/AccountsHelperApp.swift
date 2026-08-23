//
//  AccountsHelperApp.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary
import CoreData

import CoreData

//@MainActor
//func fixCommissionSigns(context: NSManagedObjectContext) throws {
//    let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
//
//    let transactions = try context.fetch(request)
//
//    for tx in transactions {
//        if tx.txAmount < 0 && tx.commissionAmount > 0 {
//            tx.commissionAmount.negate()
//            print("Fixed commission sign for transaction \(tx.id)")
//        }
//    }
//
//    if context.hasChanges {
//        try context.save()
//    }
//}

@main
struct AccountsHelperApp: App {
    
    // MARK: --- Global Variables
    let persistenceController = PersistenceController.shared
    
    // MARK: --- State: Tracks Global UI states between NavigatorView, CentralView and InspectorView
    @State private var appState = AppState()
    
    init() {
        // Enable Core Data + CloudKit debug logging
        UserDefaults.standard.set(true, forKey: "com.apple.CoreData.CloudKitDebug")
        
        persistenceController.migrateTransactionPaymentMethodToAccountIfNeeded()
        persistenceController.migrateReconciliationPaymentMethodToAccountIfNeeded()
        
        // Any other setup
        assert(MergeField.allCases.count == gNumTransactionAttributes, "MergeField count mismatch! Did you add a new field?")
        
    }
    
    // MARK: --- Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(gGlobalAlert)
                .environment(appState)
        }
    }
}

// MARK: --- Migration

extension PersistenceController {
    
    func migrateTransactionPaymentMethodToAccountIfNeeded() {
        let context = container.viewContext
        context.perform {
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(
                format: "accountCD == 0 AND paymentMethodCD != 0"
            )
            
            do {
                let results = try context.fetch(request)
                guard !results.isEmpty else { return }
                
                for tx in results {
                    tx.accountCD = tx.paymentMethodCD
                }
                
                try context.save()
                print("✅ Migrated \(results.count) transactions")
                
            } catch {
                print("❌ Migration failed: \(error)")
            }
        }
    }
    
    func migrateReconciliationPaymentMethodToAccountIfNeeded() {
        let context = container.viewContext
        context.perform {
            let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
            request.predicate = NSPredicate(
                format: "accountCD == 0 AND paymentMethodCD != 0"
            )
            
            do {
                let results = try context.fetch(request)
                guard !results.isEmpty else { return }
                
                for rec in results {
                    rec.accountCD = rec.paymentMethodCD
                }
                
                try context.save()
                print("✅ Migrated \(results.count) reconciliations")
                
            } catch {
                print("❌ Migration failed: \(error)")
            }
        }
    }
}
