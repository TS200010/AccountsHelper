import Foundation
import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct CategoryMatcherTests {

    // MARK: --- Helpers

    /// Creates a CategoryMatcher with an in-memory context
    private func makeMatcher() -> (CategoryMatcher, NSManagedObjectContext) {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        return (CategoryMatcher(context: context), context)
    }

    /// Adds a CategoryMapping to the context
    private func addMapping(
        _ normalized: String,
        category: AccountsHelper.Category,
        usageCount: Int = 0,
        context: NSManagedObjectContext
    ) {
        let mapping = CategoryMapping(context: context)
        mapping.inputString = normalized
        mapping.category = category      // uses enum wrapper
        mapping.usageCount = Int32(usageCount)
        try? context.save()
    }

    /// Adds a Transaction to the context
    private func addTransaction(
        payee: String?,
        category: AccountsHelper.Category = .unknown,
        context: NSManagedObjectContext
    ) -> Transaction {
        let tx = Transaction(context: context)
        tx.payee = payee
        tx.category = category           // uses enum wrapper
        return tx
    }

    // MARK: --- matchCategory Tests

    @Test
    func testExactMatch() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("amazon", category: .Entertainments, context: context)

        let result = matcher.matchCategory(for: "Amazon")
        #expect(result == .Entertainments)
    }

    @Test
    func testPrefixMatch() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("star", category: .FoodHousehold, context: context)

        let result = matcher.matchCategory(for: "Starbucks Coffee")
        #expect(result == .FoodHousehold)
    }

    @Test
    func testFuzzyMatch() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("gym", category: .FoodHousehold, context: context) // if you have a Health case

        let result = matcher.matchCategory(for: "Joined gym membership")
        #expect(result == .FoodHousehold)
    }

    @Test
    func testUnknownMatch() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("some", category: .Entertainments, context: context)

        let result = matcher.matchCategory(for: "Nothing matches")
        #expect(result == .unknown)
    }

    @Test
    func testUsageCountPriority() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("amazon", category: .Entertainments, usageCount: 5, context: context)
        addMapping("amazon", category: .FoodHousehold, usageCount: 10, context: context)

        let result = matcher.matchCategory(for: "Amazon")
        #expect(result == .FoodHousehold) // higher usageCount wins
    }

    // MARK: --- teachMapping Tests

    @Test
    func testTeachMappingCreatesNewMapping() async throws {
        let (matcher, context) = makeMatcher()
        matcher.teachMapping(for: "Netflix", category: .Entertainments)

        let fetch: [CategoryMapping] = try context.fetch(CategoryMapping.fetchRequest())
        #expect(fetch.contains(where: {
            $0.inputString == "netflix" && $0.category == AccountsHelper.Category.Entertainments
        }))
    }
    
    @Test
    func testTeachMappingUpdatesExistingMapping() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("netflix", category: .FoodHousehold, usageCount: 1, context: context)

        matcher.teachMapping(for: "Netflix", category: .Entertainments)
        let fetch: [CategoryMapping] = try context.fetch(CategoryMapping.fetchRequest())
        let updated = fetch.first(where: { $0.inputString == "netflix" })
        #expect(updated?.category == .Entertainments)
        #expect(updated?.usageCount ?? 0 > 1)
    }

    // MARK: --- reapplyMappingsToUnknownTransactions Tests

    @Test
    func testReapplyMappingsUpdatesUnknownTransactions() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("amazon", category: .Entertainments, context: context)
        let tx = addTransaction(payee: "Amazon", category: .unknown, context: context)

        matcher.reapplyMappingsToUnknownTransactions()
        #expect(tx.category == .Entertainments)
    }

    @Test
    func testReapplyMappingsIgnoresKnownTransactions() async throws {
        let (matcher, context) = makeMatcher()
        addMapping("amazon", category: .Entertainments, context: context)
        let tx = addTransaction(payee: "Amazon", category: .FoodHousehold, context: context)

        matcher.reapplyMappingsToUnknownTransactions()
        #expect(tx.category == .FoodHousehold) // should remain unchanged
    }

    @Test
    func testReapplyMappingsHandlesEmptyPayee() async throws {
        let (matcher, context) = makeMatcher()
        let tx = addTransaction(payee: nil, category: .unknown, context: context)

        matcher.reapplyMappingsToUnknownTransactions()
        #expect(tx.category == .unknown)
    }
}
