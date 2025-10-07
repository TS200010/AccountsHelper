//
//  CategoryMappingTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct CategoryMappingTests {

    // MARK: --- Test category getter and setter
    @Test
    func testCategoryProperty() async throws {
        // Arrange: create in-memory context and object
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let mapping = CategoryMapping(context: context)

        // Act & Assert: default unknown
        #expect(mapping.category == .unknown)

        // Set category
        mapping.category = .FoodHousehold
        #expect(mapping.category == .FoodHousehold)
        #expect(mapping.categoryRawValue == Category.FoodHousehold.rawValue)
    }

    // MARK: --- Test usage counter increments correctly
    @Test
    func testIncrementUsage() async throws {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let mapping = CategoryMapping(context: context)

        mapping.usageCount = 0
        mapping.incrementUsage()
        #expect(mapping.usageCount == 1)

        // Test saturating behavior at Int32.max
        mapping.usageCount = Int32.max
        mapping.incrementUsage()
        #expect(mapping.usageCount == Int32.max)
    }
}
