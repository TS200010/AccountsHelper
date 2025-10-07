//
//  Array+SumByCategoryIncludingSplitsTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct ArraySumByCategoryIncludingSplitsTests {

    // MARK: --- Test Sum By Category Including Splits
    @Test
    func testSumByCategoryIncludingSplitsInGBP() async throws {
        // Arrange: create in-memory context
        let context = CoreDataTestHelpers.makeInMemoryContext()

        // Create Transaction 1
        let tx1 = Transaction(context: context)
        tx1.txAmount = 10.00
        tx1.splitAmount = 4.00
        tx1.exchangeRate = 1.00      // GBP
        tx1.category = .FoodHousehold
        tx1.splitCategory = .Maintenance
        tx1.commissionAmount = 0.50

        // Create Transaction 2
        let tx2 = Transaction(context: context)
        tx2.txAmount = 25.00
        tx2.splitAmount = 10.00
        tx2.exchangeRate = 1.00
        tx2.category = .FoodHousehold
        tx2.splitCategory = .Maintenance
        tx2.commissionAmount = 0.00

        try context.save()

        let transactions = [tx1, tx2]

        // Act
        let totals = transactions.sumByCategoryIncludingSplitsInGBP()

        // Assert
        // splitAmountInGBP includes commission
        #expect(totals[.Maintenance] == Decimal(4.50 + 10.00))   // includes commission
        #expect(totals[.FoodHousehold] == Decimal(6.00 + 15.00)) // excludes commission
    }
}
