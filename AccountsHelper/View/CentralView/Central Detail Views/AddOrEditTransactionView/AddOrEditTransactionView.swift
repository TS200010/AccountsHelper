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
    
    init(transactionID: NSManagedObjectID?, context: NSManagedObjectContext, onSave: ((TransactionStruct) -> Void)? = nil) {
        if let transactionID,
           let transaction = try? context.existingObject(with: transactionID) as? Transaction {
            let structData = TransactionStruct(from: transaction)
            _transactionData = State(initialValue: structData)
            _splitTransaction = State(initialValue: structData.isSplit)
            self.existingTransaction = transaction
        } else {
            _transactionData = State(initialValue: TransactionStruct())
            _splitTransaction = State(initialValue: false)
            self.existingTransaction = nil
        }
        self.onSave = onSave
    }
    
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
                counterFXRate:        $counterFXRate
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
}
