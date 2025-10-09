//
//  NavigatorMenuView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

// MARK: --- Sidebar Button
struct SidebarButton: View {
    var title: String
    var systemImage: String
    var view: CentralViewsEnum
    var color: Color = .primary
    var optionalSheetBinding: Binding<Bool>
    
    @Environment(AppState.self) private var appState
    
    // Fixed width and minimum height
    private let iconWidth: CGFloat = 20
    private let minButtonHeight: CGFloat = 30
    
    var body: some View {
        Button {
            #if os(macOS)
            appState.replaceCentralView(with: view)
            #else
            // Note the appropriate binding will be passed in 
            switch view {
            case .addTransaction:
                optionalSheetBinding.wrappedValue = true
            case .browseTransactions(_):
                optionalSheetBinding.wrappedValue = true
            default:
                optionalSheetBinding.wrappedValue = false
            }
            #endif
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(appState.selectedCentralView == view ? .white : color)
                    .frame(width: iconWidth, alignment: .trailing)
                Text(title)
                    .foregroundColor(appState.selectedCentralView == view ? .white : .primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: minButtonHeight, alignment: .leading)
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(appState.selectedCentralView == view ? Color.accentColor : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: --- Enum Extension for iOS
extension CentralViewsEnum {
    var isBrowseTransaction: Bool {
        switch self {
        case .browseTransactions: return true
        default: return false
        }
    }
}

// MARK: --- NavigatorMenuView
struct NavigatorMenuView: View {
    
    // MARK: --- Environment
    @Environment(AppState.self) var appState
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: --- iOS sheet state
    @State private var showingEditAddTransactionSheet: Bool = false
    @State private var showingBrowseTransactionsView: Bool = false
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 4) {
            
            SidebarButton(title: "Add Transaction",
                          systemImage: "plus.circle",
                          view: .addTransaction,
                          color: .blue,
                          optionalSheetBinding: $showingEditAddTransactionSheet)
            
            Divider()
            
            SidebarButton(title: "Browse Transactions",
                          systemImage: "list.bullet",
                          view: .browseTransactions(nil),
                          color: .purple,
                          optionalSheetBinding: $showingBrowseTransactionsView)
            
            SidebarButton(title: "Browse Categories",
                          systemImage: "tag",
                          view: .browseCategories,
                          color: .orange,
                          optionalSheetBinding: .constant(false) )
            
            Divider()
            
            SidebarButton(title: "Import AMEX CSV Transactions",
                          systemImage: "doc.text",
                          view: .AMEXCSVImport,
                          color: .red,
                          optionalSheetBinding:  .constant(false))
            
            SidebarButton(title: "Import BofS CSV Transactions",
                          systemImage: "doc.text",
                          view: .BofSCSVImport,
                          color: .green,
                          optionalSheetBinding: .constant(false))
            
            SidebarButton(title: "Import VISA PNG Transactions",
                          systemImage: "photo",
                          view: .VISAPNGImport,
                          color: .yellow,
                          optionalSheetBinding: .constant(false))
            
            Divider()
            
            SidebarButton(title: "Reconciliation",
                          systemImage: "checkmark.seal",
                          view: .reconcilliationListView,
                          color: .teal,
                          optionalSheetBinding: .constant(false))
            
            Divider()
            
            SidebarButton(title: "Export Transactions",
                          systemImage: "square.and.arrow.up",
                          view: .exportCD,
                          color: .black,
                          optionalSheetBinding: .constant(false))
            
            Divider()
            
            SidebarButton(title: "Import Transactions",
                          systemImage: "square.and.arrow.down",
                          view: .importCD,
                          color: .black,
                          optionalSheetBinding: .constant(false))
            
            Divider()
            
            SidebarButton(title: "Edit Currency",
                          systemImage: "dollarsign.circle",
                          view: .editCurrency,
                          color: .brown,
                          optionalSheetBinding: .constant(false))
            
            SidebarButton(title: "Edit Payer",
                          systemImage: "person.crop.circle",
                          view: .editPayer,
                          color: .mint,
                          optionalSheetBinding: .constant(false))
            
            SidebarButton(title: "Edit Payee",
                          systemImage: "person.2",
                          view: .editPayee,
                          color: .cyan,
                          optionalSheetBinding: .constant(false))
            
            Spacer()
        }
        .padding(.horizontal, 8)
        
        #if os(iOS)
        .sheet(isPresented: $showingEditAddTransactionSheet) {
            AddOrEditTransactionView()
        }
        .sheet(isPresented: $showingBrowseTransactionsView) {
            BrowseTransactionsView()
        }
        #endif
    }
}
