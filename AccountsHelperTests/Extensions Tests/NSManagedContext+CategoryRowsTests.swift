//  NSManagedContextCategoryRowsTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct NSManagedContextCategoryRowsTests {

    // MARK: --- Helper: In-Memory CoreData Context
    private func makeInMemoryContext() -> NSManagedObjectContext {
        let modelName = "AccountsHelperModel" // exact name of your .xcdatamodeld (without extension)

        // ✅ Lookup the model in the main app bundle, not the test bundle
        guard
            let modelURL = Bundle(for: Transaction.self)
                .url(forResource: modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("❌ Failed to load Core Data model \(modelName) from app bundle")
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        return container.viewContext
    }


    // MARK: --- categoryTotals Tests

    @Test
    func testCategoryTotalsEmptyContextReturnsZero() async throws {
        let context = makeInMemoryContext()
        let predicate = NSPredicate(value: true) // matches all
        let result = context.categoryTotals(for: predicate)

        for category in Category.allCases {
            #expect(result[category] == 0)
        }
    }

    @Test
    func testCategoryTotalsWithSingleTransaction() async throws {
        let context = makeInMemoryContext()
        guard let splitCat = Category.allCases.first,
              let remainderCat = Category.allCases.dropFirst().first else { return }

        let tx = Transaction(context: context)
        tx.splitCategory = splitCat
        tx.splitAmountCD = 1000           // 10 GBP
        tx.categoryCD = remainderCat.rawValue
        tx.txAmountCD = 1500               // total 15 GBP
        tx.exchangeRateCD = 100
        tx.commissionAmountCD = 0
        tx.paymentMethodCD = ReconcilableAccounts.CashGBP.rawValue
        tx.transactionDate = Date()

        try context.save()

        let predicate = NSPredicate(value: true)
        let result = context.categoryTotals(for: predicate)

        #expect(result[splitCat] == 10)       // splitAmountInGBP = 10
        #expect(result[remainderCat] == 5)    // remainder = 15 - 10 = 5
    }

    @Test
    func testCategoryTotalsWithPredicateFiltering() async throws {
        let context = makeInMemoryContext()
        let splitCat = Category.FoodHousehold
        let remainderCat = Category.Maintenance

        let tx1 = Transaction(context: context)
        tx1.splitCategory = splitCat
        tx1.splitAmountCD = 1000            // 10 GBP
        tx1.categoryCD = remainderCat.rawValue
        tx1.txAmountCD = 1200                // total 12 GBP
        tx1.exchangeRateCD = 100
        tx1.paymentMethodCD = ReconcilableAccounts.CashGBP.rawValue
        tx1.transactionDate = Date()

        let tx2 = Transaction(context: context)
        tx2.splitCategory = splitCat
        tx2.splitAmountCD = 500             // 5 GBP
        tx2.categoryCD = remainderCat.rawValue
        tx2.txAmountCD = 800                  // total 8 GBP
        tx2.exchangeRateCD = 100
        tx2.paymentMethodCD = ReconcilableAccounts.AMEX.rawValue
        tx2.transactionDate = Date()

        try context.save()

        let predicate = NSPredicate(format: "paymentMethodCD == %d", ReconcilableAccounts.CashGBP.rawValue)
        let result = context.categoryTotals(for: predicate)

        #expect(result[splitCat] == 10)      // only tx1 counted
        #expect(result[remainderCat] == 2)   // 12 - 10 = 2
    }
}
