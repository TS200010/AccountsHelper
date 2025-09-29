//
//  CentralViews.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

import SwiftUI
import ItMkLibrary

struct CentralViews: View {
    
    @Environment(AppState.self) var appState
    
    var body: some View {
        
        // We are doing this ZStack to avoid endlessly adding more and more views.
        ZStack {
            // Base view (saved or current)
            getView(for: appState.savedCentralView ?? appState.selectedCentralView)
                .id(appState.savedCentralView ?? appState.selectedCentralView)
                .transition(.opacity)
            
            // Overlay only if a new view is pushed
            if let overlay = overlayView {
                getView(for: overlay)
                    .id(overlay)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: overlay)
                    .background(Color(Color.platformTextBackgroundColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Color.platformTextBackgroundColor))
    }
    
    // Overlay exists only if selected differs from saved
    private var overlayView: CentralViewsEnum? {
        guard let saved = appState.savedCentralView,
              saved != appState.selectedCentralView else { return nil }
        return appState.selectedCentralView
    }
    
    // Map enum to actual views
    @ViewBuilder
    private func getView(for viewEnum: CentralViewsEnum?) -> some View {
        switch viewEnum {
        case .emptyView, .none:
            Text("Select an action from the toolbar")
            
        case .addTransaction:
            EditTransactionView()
            
        case .editTransaction:
            EditTransactionView()
                  
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
            
//        case .reconciliationTransactionDetail:
//            Text("ReconcilliationDetailView(reconciliation: xxxx)")
////            ReconcilliationDetailView(reconciliation: <#Reconciliation#>)
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
            
        case .transactionSummary( let txs, let pmt ):
            TransactionSummaryView( transactions: txs, paymentMethod: pmt )
    
        }
        
    }
}

//struct CentralViews: View {
//    
//    @Environment(AppState.self) var appState
//    
//    // MARK: --- Body
//    var body: some View {
//        ZStack {
//            switch appState.selectedCentralView {
//                
//            case .emptyView:
//                Text("Select an action from the toolbar")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .addTransaction:
//                EditTransactionView()
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .editTransaction:
//                EditTransactionView()
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .AMEXCSVImport:
//                #if os(macOS)
//                CSVImportView()
//                    .id(UUID())
//                    .transition(.opacity)
//
//                #else
//                Text("Not implemented on iOS")
//                    .id(UUID())
//                    .transition(.opacity)
//                #endif
//                
//            case .browseCategories:
//                #if os(macOS)
//                BrowseCategoriesView()
//                    .id(UUID())
//                    .transition(.opacity)
//                #else
//                Text("Not implemented on iOS")
//                    .id(UUID())
//                    .transition(.opacity)
//                #endif
//                
//            case .editCurrency:
//                Text("Edit Currency View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .editPayee:
//                Text("Edit Payee View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .editPayer:
//                Text("Edit Payer View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .reconcilliationListView:
//                Text("Reconcile Transactions View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .browseTransactions:
//                BrowseTransactionsView()
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .browseCurrencies:
//                Text("Browse Currencies View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .browsePayees:
//                Text("Browse Payees View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .browsePayers:
//                Text("Browse Payers View")
//                    .id(UUID())
//                    .transition(.opacity)
//                
//            case .reports:
//                Text("Reports View")
//                    .id(UUID())
//                    .transition(.opacity)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(Color.platformTextBackgroundColor))
//        .animation(.default, value: appState.selectedCentralView)
//    }
//}



//import SwiftUI
//import ItMkLibrary
//
//struct CentralViews: View {
//    
//    @Environment(AppState.self) var appState
//    
//    //TODO: See if we need this. We probably dont if we follow List selection binding
////    func tapAction( rowTapped: Int ) -> Void {
////        appState.selectedRecord = rowTapped
////
////    }
//    
//    
//    // MARK: --- Body
//    var body: some View {
//        
//        VStack (spacing: 0) {
//            
//            switch appState.selectedCentralView {
//                
//            case .emptyView:
//                Text("Select an action from the toolbar" )
//                
//            case .addTransaction:
//                EditTransactionView()
//                
//            case .AMEXCSVImport:
//                #if os(macOS)
//                CSVImportView()
//                #else
//                Text("Not implemented on iOS" )
//                #endif
//                
//            case .browseCategories:
//#if os(macOS)
//BrowseCategoriesView()
//#else
//Text("Not implemented on iOS" )
//#endif
//                
//            case .editTransaction:
//                //                EditTransactionViewOld()
//                EditTransactionView()
//                
//            case .editCurrency:
//                Text("Edit Currency View")
//                
//            case .editPayee:
//                Text("Edit Payee View")
//                
//            case .editPayer:
//                Text("Edit Payer View")
//                
//            case .reconcilliationListView:
//                Text("Reconcile Transactions View")
//                
//            case .browseTransactions:
//                BrowseTransactionsView()
//                
//            case .browseCurrencies:
//                Text("Browse Currencies View")
//                
//            case .browsePayees:
//                Text("Browse Payees View")
//                
//            case .browsePayers:
//                Text("Browse Payers View")
//                
//                
//            case .reports:
//                Text("Reports View")
//                
//            }
//            
//        } .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background( Color( Color.platformTextBackgroundColor ) )
//          .if( gViewCheck ) { view in view.border( .red )}
//    }
//}
//
//
