//  GlobalsTests.swift
//  From SkeletonMacOSAppTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Testing
import ItMkLibrary
@testable import AccountsHelper

@MainActor
struct GlobalsTests {

    // MARK: --- AppState Tests

    @Test
    func testPushAndPopCentralView() async throws {
        let state = AppState()
        let initial = state.selectedCentralView

        // Use a safe enum case
        let testView = CentralViewsEnum.editTransaction(existingTransaction: nil)
        state.pushCentralView(testView)
        #expect(state.selectedCentralView == testView)

        state.popCentralView()
        #expect(state.selectedCentralView == initial)
    }

    @Test
    func testReplaceCentralView() async throws {
        let state = AppState()
        let testView = CentralViewsEnum.browseTransactions(nil)
        state.replaceCentralView(with: testView)
        #expect(state.selectedCentralView == testView)
    }

    @Test
    func testReplaceInspectorView() async throws {
        let state = AppState()
        // Use the emptyView for InspectorViewsEnum as a minimal case
        let testInspectorView = InspectorViewsEnum.emptyView
        state.replaceInspectorView(with: testInspectorView)
        #expect(state.selectedInspectorView == testInspectorView)
    }

    @Test
    func testRefreshInspectorIncrementsTrigger() async throws {
        let state = AppState()
        let initialTrigger = state.inspectorRefreshTrigger
        state.refreshInspector()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(state.inspectorRefreshTrigger == initialTrigger + 1)
    }

}
