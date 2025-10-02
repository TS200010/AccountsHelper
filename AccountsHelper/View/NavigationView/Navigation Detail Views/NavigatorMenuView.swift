//
//  NavigatorMenuView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

struct ItMkSidebarButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(6)
    }
}

struct NavigatorMenuView: View {
    
    // MARK: --- Environment
    @Environment(AppState.self) var appState
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: --- Properties
    // Used for simplified iOS navigation
    @State private var showingEditAddTransactionSheet = false
    @State private var showingBrowseTransactionsView = false
    
    // MARK: --- Body
    var body: some View {
        
        VStack {
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .addTransaction)
                #else
                appState.selectedCentralView = .addTransaction
                showingEditAddTransactionSheet = true
                #endif
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(appState.selectedCentralView == .addTransaction ? .white : .blue)
                    Text("Add Transaction")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .addTransaction))
            
            Divider()
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .browseTransactions(nil))
                #else
                appState.selectedCentralView = .browseTransactions(nil)
                showingBrowseTransactionsView = true
                #endif
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor({
                            if case .browseTransactions = appState.selectedCentralView { return .white }
                            return .purple
                        }())
                    Text("Browse Transactions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: {
                if case .browseTransactions = appState.selectedCentralView { return true }
                return false
            }()))
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .browseCategories)
                #else
                appState.selectedCentralView = .browseTransactions
                #endif
            } label: {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(appState.selectedCentralView == .browseCategories ? .white : .orange)
                    Text("Browse Categories")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .browseCategories))
            
            Divider()
            
            Button {
                #if os(macOS)
                let paymentMethod: PaymentMethod = .CashGBP
                let currency: Currency = .GBP
                let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                let endDate = Date()
                let transactions = Transaction.generateRandomTransactions(
                    for: paymentMethod,
                    currency: currency,
                    startDate: startDate,
                    endDate: endDate,
                    count: 30,
                    in: viewContext
                )
                #else
                // no iOS action
                #endif
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                        .foregroundColor(.pink)
                    Text("Add Random Transactions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(gUseLiveStore)
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: false))
            
            Divider()
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .AMEXCSVImport)
                #endif
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(appState.selectedCentralView == .AMEXCSVImport ? .white : .red)
                    Text("Import AMEX CSV Transactions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .AMEXCSVImport))
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .BofSCSVImport)
                #endif
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(appState.selectedCentralView == .BofSCSVImport ? .white : .green)
                    Text("Import BofS CSV Transactions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .BofSCSVImport))
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .VISAPNGImport)
                #endif
            } label: {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(appState.selectedCentralView == .VISAPNGImport ? .white : .yellow)
                    Text("Import VISA PNG Transactions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .VISAPNGImport))
            
            Divider()
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .reconcilliationListView)
                #endif
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal")
                        .foregroundColor(appState.selectedCentralView == .reconcilliationListView ? .white : .teal)
                    Text("Reconciliation")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .reconcilliationListView))
            
            Divider()
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .editCurrency)
                #endif
            } label: {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(appState.selectedCentralView == .editCurrency ? .white : .brown)
                    Text("Edit Currency")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .editCurrency))
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .editPayer)
                #endif
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(appState.selectedCentralView == .editPayer ? .white : .mint)
                    Text("Edit Payer")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .editPayer))
            
            Button {
                #if os(macOS)
                appState.replaceCentralView(with: .editPayee)
                #endif
            } label: {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(appState.selectedCentralView == .editPayee ? .white : .cyan)
                    Text("Edit Payee")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ItMkSidebarButtonStyle(isSelected: appState.selectedCentralView == .editPayee))
        }
        .padding(.horizontal, 8)


#if os(iOS)
        .sheet(isPresented: $showingEditAddTransactionSheet) {
            EditTransactionView()
        }
        .sheet(isPresented: $showingBrowseTransactionsView) {
            BrowseTransactionsView()
        }
#endif
        Spacer()
    }
}
