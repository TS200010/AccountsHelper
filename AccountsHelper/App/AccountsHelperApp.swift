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

//func normalizeOpeningBalances(in context: NSManagedObjectContext) {
//    let fetchRequest: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
//    
//    // Fetch any reconciliation with year == 1
//    fetchRequest.predicate = NSPredicate(format: "periodYear == 1")
//    
//    do {
//        let openingBalances = try context.fetch(fetchRequest)
//        let calendar = Calendar(identifier: .gregorian)
//        for rec in openingBalances {
//            // Normalize year and month
//            rec.periodYear = 1
//            rec.periodMonth = 1
//            
//            // Normalize statementDate to 1 Jan 0001
//            rec.statementDate = calendar.date(from: DateComponents(year: 1, month: 1, day: 1))
//        }
//        
//        try context.save()
//        print("Normalized \(openingBalances.count) opening balances to 1/1/1")
//    } catch {
//        print("Failed to normalize opening balances: \(error)")
//        context.rollback()
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
        
        // Any other setup
        assert(MergeField.allCases.count == gNumTransactionAttributes, "🚨 MergeField count mismatch! Did you add a new field?")
        
        // --- One-time fix: normalize opening balances ---
//        normalizeOpeningBalances(in: persistenceController.container.viewContext)
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
