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
    
    //TODO: See if we need this. We probably dont if we follow List selection binding
//    func tapAction( rowTapped: Int ) -> Void {
//        appState.selectedRecord = rowTapped
//
//    }
    
    
    // MARK: --- Body
    var body: some View {
        
        VStack (spacing: 0) {
            
            switch appState.selectedCentralView {
                
            case .emptyView:
                Text("Select an action from the toolbar" )
                
            case .addTransaction:
                EditTransactionSheet()
                
            case .AMEXCSVImport:
                #if os(macOS)
                CSVImportView()
                #else
                Text("Not implemented on iOS" )
                #endif
                
            case .browseCategories:
#if os(macOS)
BrowseCategoriesView()
#else
Text("Not implemented on iOS" )
#endif
                
            case .editTransaction:
                //                EditTransactionViewOld()
                EditTransactionSheet()
                
            case .editCurrency:
                Text("Edit Currency View")
                
            case .editPayee:
                Text("Edit Payee View")
                
            case .editPayer:
                Text("Edit Payer View")
                
            case .reconcileTransactions:
                Text("Reconcile Transactions View")
                
            case .browseTransactions:
                BrowseTransactionsView()
                
            case .browseCurrencies:
                Text("Browse Currencies View")
                
            case .browsePayees:
                Text("Browse Payees View")
                
            case .browsePayers:
                Text("Browse Payers View")
                
                
            case .reports:
                Text("Reports View")
                
            }
            
        } .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background( Color( Color.platformTextBackgroundColor ) )
          .if( gViewCheck ) { view in view.border( .red )}
    }
}


