//
//  AddOrEditTransactionView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import SwiftUI
import CoreData
import ItMkLibrary

// MARK: --- Main View
struct AddOrEditTransactionView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) internal var viewContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    // MARK: --- State
    @State internal var transactionData: TransactionStruct
    @State private var splitTransaction: Bool
    @FocusState internal var focusedField: AmountFieldIdentifier?
    // Counter Transaction
    @State internal var counterTransactionActive: Bool = false
    @State internal var counterAccount: ReconcilableAccounts? = nil
    @State internal var counterFXRate: Decimal = 0
    @State internal var counterExistsOnLoad: Bool = false
    
    // MARK: --- External
    var existingTransaction: Transaction?
    var onSave: ((TransactionStruct) -> Void)?
    
    // MARK: --- Initialisers
    init(transaction: Transaction? = nil, onSave: ((TransactionStruct) -> Void)? = nil) {
        if let transaction {
            let structData = TransactionStruct(from: transaction)
            _transactionData = State(initialValue: structData)
            _splitTransaction = State(initialValue: structData.isSplit)
        } else {
            _transactionData = State(initialValue: TransactionStruct())
            _splitTransaction = State(initialValue: false)
        }
        self.existingTransaction = transaction
        self.onSave = onSave
    }
    
//    init(transactionID: NSManagedObjectID?, context: NSManagedObjectContext, onSave: ((TransactionStruct) -> Void)? = nil) {
//        if let transactionID,
//           let transaction = try? context.existingObject(with: transactionID) as? Transaction {
//            let structData = TransactionStruct(from: transaction)
//            _transactionData = State(initialValue: structData)
//            _splitTransaction = State(initialValue: structData.isSplit)
//            self.existingTransaction = transaction
//        } else {
//            _transactionData = State(initialValue: TransactionStruct())
//            _splitTransaction = State(initialValue: false)
//            self.existingTransaction = nil
//        }
//        self.onSave = onSave
//    }
    
    // MARK: --- CanSave
    private var canSave: Bool {
        guard let txDate = transactionData.transactionDate else { return false }
        return txDate <= Date() &&
        transactionData.txAmount != 0 &&
        (transactionData.payee?.isEmpty == false) &&
        transactionData.category != .unknown &&
        (transactionData.currency == .GBP ||
         (transactionData.exchangeRate != 0 && (transactionData.currency == .JPY ? transactionData.exchangeRate < 300 : true)))
    }
    
    // MARK: --- Body
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                //                header
                mainFields
                splitSection
                actionButtons
            }
            .frame(maxWidth: 700)
            .font(.system(size: 11))
            .padding()
            .onTapGesture { focusedField = nil }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            populateFromExistingTransaction()
        }
    }

    
    // MARK: --- Split Section
    private var splitSection: some View {
    #if os(iOS)
        VStack(spacing: 16) {
            SplitTransactionView(
                transactionData: $transactionData,
                splitTransaction: $splitTransaction,
//                focusedField: $focusedField
            )
            CounterTransactionView(
                transactionData: $transactionData,
                counterTransaction: $counterTransactionActive,
                counterAccount: $counterAccount,
                counterFXRate:        $counterFXRate

            )
        }
    #elseif os(macOS)
        HStack(alignment: .top, spacing: 16) {
            SplitTransactionView(
                transactionData:     $transactionData,
                splitTransaction:    $splitTransaction,
            )
            .frame(minWidth: 300)
            .focused($focusedField, equals: .splitAmountField)

            CounterTransactionView(
                transactionData:      $transactionData,
                counterTransaction:   $counterTransactionActive,
                counterAccount:       $counterAccount,
                counterFXRate:        $counterFXRate,
                canRemoveCounter:     !counterExistsOnLoad
            )
            .frame(minWidth: 300)
        }
    #endif
    }

    
    // MARK: --- Action Buttons
    private var actionButtons: some View {
        GroupBox(label: Label("Transaction Disposition", systemImage: "square.and.arrow.down")) {
            HStack {
                Spacer()
                Button("Don't Save", role: .cancel) {
                    appState.popCentralView()
                    resetForm()
#if os(iOS)
                    dismiss()
#endif
                }
                .padding()
                
                Button("Save") {
                    saveTransaction()
                    appState.popCentralView()
                    resetForm()
#if os(iOS)
                    dismiss()
#endif
                }
                .disabled(!transactionData.isValid())
                .buttonStyle(.borderedProminent)
                .padding()
                Spacer()
            }
        }
    }
    
    // MARK: --- LoadCounterIfPresent
    private func loadCounterIfPresent() {
        guard let tx = existingTransaction else { return }
        guard let counterTx = tx.counterTransaction(in: viewContext) else { return }

        // Mark counter mode active
        counterTransactionActive = true

        // Set counter account
        counterAccount = counterTx.account

        // Set FX rate
        counterFXRate = counterTx.exchangeRate

        // Now populate UI fields for counter currency
        // Note: you may need to adjust based on your actual fields
        transactionData.currency = counterTx.currency
        transactionData.txAmount = counterTx.txAmount
    }
    
    // MARK: --- PopulateFromExistingTransaction
    private func populateFromExistingTransaction() {
        guard let tx = existingTransaction else { return }

        // Main transaction data already populated elsewhere
        // Now check for counter transaction
        if let counterTx = tx.counterTransaction(in: viewContext) {
            counterTransactionActive = true
            counterAccount = counterTx.account
            counterFXRate = counterTx.exchangeRate
            counterExistsOnLoad = true
        } else {
            counterTransactionActive = false
            counterAccount = nil
            counterFXRate = 0
            counterExistsOnLoad = false
        }
    }
}
