//
//  CentralViews.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct CentralViews: View {
    @Environment(AppState.self) var appState

    var body: some View {
        ZStack {
            ForEach(Array(appState.centralViewStack.enumerated()), id: \.element) { index, viewEnum in
                getView(for: viewEnum)
                    .id(viewEnum) // keep SwiftUI from reusing
                    .zIndex(Double(index))
                    .opacity(index == appState.centralViewStack.count - 1 ? 1 : 0) // hide lower ones
                    .allowsHitTesting(index == appState.centralViewStack.count - 1) // only top interactive
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Color.platformTextBackgroundColor))
    }

    // Map enum to actual views
    @ViewBuilder
    private func getView(for viewEnum: CentralViewsEnum) -> some View {
        switch viewEnum {
        case .emptyView:
            Text("Select an action from the toolbar")

        case .addTransaction:
            EditTransactionView()

        case .editTransaction(let tx):
            EditTransactionView( transaction: tx )

        case .browseTransactions(let predicate):
            BrowseTransactionsView(predicate: predicate)

        case .browseCategories:
            #if os(macOS)
            BrowseCategoriesView()
            #else
            Text("Not implemented on iOS")
            #endif

        case .reports:
            Text("Reports View")

        case .AMEXCSVImport:
            #if os(macOS)
            AMEXCSVImportView()
            #else
            Text("Not implemented on iOS")
            #endif

        case .editCurrency:
            Text("Edit Currency View")

        case .editPayee:
            Text("Edit Payee View")

        case .editPayer:
            Text("Edit Payer View")

        case .reconcilliationListView:
            ReconcilliationListView()

        case .reconciliationTransactionDetail(let predicate):
            BrowseTransactionsView(predicate: predicate)

        case .browseCurrencies:
            Text("Browse Currencies View")

        case .browsePayees:
            Text("Browse Payees View")

        case .browsePayers:
            Text("Browse Payers View")

        case .transactionMergeView(let txs, let onComplete):
            MergeTransactionsView(transactions: txs, onComplete: onComplete)

        case .transactionSummary(let predicate):
            TransactionsSummaryView(predicate: predicate)
        }
    }
}
