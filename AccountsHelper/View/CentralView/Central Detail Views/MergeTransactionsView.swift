//
//  MergeTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 28/09/2025.
//

import SwiftUI
import CoreData

// MARK: --- Mergeable Fields
enum MergeField: String, CaseIterable, Identifiable {
    case timestamp
    case transactionDate
    case paymentMethod
    case category
    case txAmount
    case currency
    case exchangeRate
    case payee
    case payer
    case splitAmount
    case splitCategory
    case accountNumber
    case address
    case commissionAmount
    case debitCredit
    case explanation
    case extendedDetails
    case accountingPeriod
    case reference

    var id: String { rawValue }
}


// MARK: --- Field Metadata
struct MergeFieldInfo {
    let displayName: String
    let getter: (Transaction) -> String
    let hasValue: (Transaction) -> Bool
    let setter: (Transaction, Transaction) -> Void
}

// MARK: --- MergeField
extension MergeField {
    static let all: [MergeField: MergeFieldInfo] = [
        .txAmount: MergeFieldInfo(
            displayName: "Amount",
            getter: { $0.txAmountAsString() },
            hasValue: { $0.txAmount != 0 },
            setter: { $0.txAmount = $1.txAmount }
        ),
        .splitAmount: MergeFieldInfo(
            displayName: "Split Amount",
            getter: { $0.splitAmountAsString() },
            hasValue: { $0.splitAmount != 0 },
            setter: { $0.splitAmount = $1.splitAmount }
        ),
        .category: MergeFieldInfo(
            displayName: "Category",
            getter: { $0.category.description },
            hasValue: { $0.category != .unknown },
            setter: { $0.category = $1.category }
        ),
        .splitCategory: MergeFieldInfo(
            displayName: "Split Category",
            getter: { $0.splitCategory.description },
            hasValue: { $0.splitCategory != .unknown },
            setter: { $0.splitCategory = $1.splitCategory }
        ),
        .currency: MergeFieldInfo(
            displayName: "Currency",
            getter: { $0.currency.description },
            hasValue: { $0.currency != .unknown },
            setter: { $0.currency = $1.currency }
        ),
        .debitCredit: MergeFieldInfo(
            displayName: "Debit/Credit",
            getter: { $0.debitCredit.description },
            hasValue: { $0.debitCredit != .unknown },
            setter: { $0.debitCredit = $1.debitCredit }
        ),
        .payer: MergeFieldInfo(
            displayName: "Payer",
            getter: { $0.payer.description },
            hasValue: { $0.payer != .unknown },
            setter: { $0.payer = $1.payer }
        ),
        .payee: MergeFieldInfo(
            displayName: "Payee",
            getter: { $0.payee ?? "" },
            hasValue: { ($0.payee ?? "").isEmpty == false },
            setter: { $0.payee = $1.payee }
        ),
        .paymentMethod: MergeFieldInfo(
            displayName: "Account",
            getter: { $0.paymentMethod.description },
            hasValue: { $0.paymentMethod != .unknown },
            setter: { $0.paymentMethod = $1.paymentMethod }
        ),
        .explanation: MergeFieldInfo(
            displayName: "Explanation",
            getter: { $0.explanation ?? "" },
            hasValue: { ($0.explanation ?? "").isEmpty == false },
            setter: { $0.explanation = $1.explanation }
        ),
        .transactionDate: MergeFieldInfo(
            displayName: "Date",
            getter: { $0.transactionDateAsString() ?? "" },
            hasValue: { $0.transactionDate != nil },
            setter: { $0.transactionDate = $1.transactionDate }
        ),
//        .accountingPeriod: MergeFieldInfo(
//            displayName: "Accounting Period",
//            getter: { $0.accountingPeriod ?? "" },
//            hasValue: { ($0.accountingPeriod ?? "").isEmpty == false },
//            setter: { $0.accountingPeriod = $1.accountingPeriod }
//        ),
        .accountNumber: MergeFieldInfo(
            displayName: "External Account Number",
            getter: { $0.accountNumber ?? "" },
            hasValue: { ($0.accountNumber ?? "").isEmpty == false },
            setter: { $0.accountNumber = $1.accountNumber }
        ),
        .address: MergeFieldInfo(
            displayName: "Address",
            getter: { $0.address ?? "" },
            hasValue: { ($0.address ?? "").isEmpty == false },
            setter: { $0.address = $1.address }
        ),
        .commissionAmount: MergeFieldInfo(
            displayName: "Commission Amount",
            getter: { $0.commissionAmountAsString() ?? "" },
            hasValue: { $0.commissionAmount != 0 },
            setter: { $0.commissionAmount = $1.commissionAmount }
        ),
        .exchangeRate: MergeFieldInfo(
            displayName: "Exchange Rate",
            getter: { $0.exchangeRateAsStringLong() ?? "" },
            hasValue: { $0.exchangeRate != 0 },
            setter: { $0.exchangeRate = $1.exchangeRate }
        ),
        .extendedDetails: MergeFieldInfo(
            displayName: "Extended Details",
            getter: { $0.extendedDetails ?? "" },
            hasValue: { ($0.extendedDetails ?? "").isEmpty == false },
            setter: { $0.extendedDetails = $1.extendedDetails }
        ),
        .reference: MergeFieldInfo(
            displayName: "Reference",
            getter: { $0.reference ?? "" },
            hasValue: { ($0.reference ?? "").isEmpty == false },
            setter: { $0.reference = $1.reference }
        ),
        .timestamp: MergeFieldInfo(
            displayName: "Timestamp",
            getter: { $0.timestampAsString() ?? "" },
            hasValue: { $0.timestamp != nil },
            setter: { $0.timestamp = $1.timestamp }
        )
    ]
}

// MARK: --- MergeTransactionsView
struct MergeTransactionsView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: --- Injected
    let transactions: [Transaction]
    var onComplete: ((MergeResult) -> Void)? = nil

    // MARK: --- State
    @State private var selectedSide: [MergeField: Bool] = [:]
    @State private var autoPicked: [MergeField: Bool] = [:]

    // MARK: --- Local Variables
    private var leftTransaction: Transaction { transactions[0] }
    private var rightTransaction: Transaction { transactions[1] }
    

    // MARK: --- View Body
    var body: some View {
        VStack {
//            Text("Merge Transactions")
//                .font(.headline)
//                .padding()
//            
            // --- Headings ---
            HStack {
                Spacer().frame(width: 150) // space for the field names column
                Text("        Existing Transaction")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer().frame(width: 80) // space for slider
                Text("New Transaction")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            // --- Fields ---
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(MergeField.allCases) { field in
                        if let info = MergeField.all[field] {
                            HStack {
                                Text(info.displayName)
                                    .frame(width: 150, alignment: .leading)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(info.getter(leftTransaction))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(6)
                                    .background(background(for: field, isLeft: true))
                                    .cornerRadius(4)

                                Slider(
                                    value: Binding(
                                        get: { (selectedSide[field] ?? true) ? 0.0 : 1.0 },
                                        set: { newValue in
                                            selectedSide[field] = (newValue < 0.5)
                                            autoPicked[field] = false
                                        }
                                    ),
                                    in: 0...1
                                )
                                .frame(width: 80)

                                Text(info.getter(rightTransaction))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(6)
                                    .background(background(for: field, isLeft: false))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                
                Button("Cancel Merge") {
                    // signal to stop further merging
                    onComplete?(.cancelMerge)
                    appState.popCentralView()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .padding(.leading)
                
                Button("Keep Existing") {
                    appState.popCentralView()
                    onComplete?(.keepExisting)
                }

                Button("Keep New") {
                    viewContext.delete(leftTransaction)
                    do {
                        try viewContext.save()
                    } catch {
                        viewContext.rollback()
                    }
                    appState.popCentralView()
                    onComplete?(.keepNew)
                }

                Button("Keep Both") {
                    appState.popCentralView()
                    onComplete?(.keepBoth)
                }

                Button("Merge") {
                    mergeTransactions()
                    appState.popCentralView()
                    onComplete?(.merged)
                }

//                Button("Cancel") {
//                    appState.popCentralView()
//                    onComplete?()
//                }
//                .padding(.trailing)
//
//                Button("Merge") {
//                    mergeTransactions()
//                    appState.popCentralView()
//                    onComplete?()
//                }
//                .buttonStyle(.borderedProminent)
//                .disabled(transactions.count != 2)
                
            }
            .padding()
        }
        .onAppear { preloadSelections() }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: --- HELPERS
    // MARK: --- Background
    private func background(for field: MergeField, isLeft: Bool) -> Color {
        guard let pickedLeft = selectedSide[field] else { return .clear }
        let info = MergeField.all[field]!
        let leftValue = info.getter(leftTransaction)
        let rightValue = info.getter(rightTransaction)

        if !leftValue.isEmpty && leftValue == rightValue {
            return Color.green.opacity(0.3)
        }
        if leftValue.isEmpty && rightValue.isEmpty {
            return Color.green.opacity(0.3)
        }

        let isSelected = (isLeft && pickedLeft) || (!isLeft && !pickedLeft)
        if isSelected {
            return (autoPicked[field] ?? false) ? Color.green.opacity(0.3) : Color.accentColor.opacity(0.2)
        }
        return .clear
    }

    // MARK: --- PreloadSelections
    private func preloadSelections() {
        for field in MergeField.allCases {
            guard let info = MergeField.all[field] else { continue }
            let leftHas = info.hasValue(leftTransaction)
            let rightHas = info.hasValue(rightTransaction)

            if leftHas && !rightHas {
                selectedSide[field] = true
                autoPicked[field] = true
            } else if !leftHas && rightHas {
                selectedSide[field] = false
                autoPicked[field] = true
            } else if !leftHas && !rightHas {
                selectedSide[field] = true
                autoPicked[field] = true
            } else {
                selectedSide[field] = true
                autoPicked[field] = false
            }
        }
    }

    // MARK: --- MergeTransactions
    private func mergeTransactions() {
        viewContext.performAndWait {
            for field in MergeField.allCases {
                let useLeft = selectedSide[field] ?? true
                let source = useLeft ? leftTransaction : rightTransaction
                MergeField.all[field]?.setter(leftTransaction, source)
            }
            viewContext.delete(rightTransaction)

            do {
                try viewContext.save()
                DispatchQueue.main.async {
                    appState.refreshInspector()
                }
            } catch {
                print("Failed to merge transactions: \(error)")
                viewContext.rollback()
            }
        }
    }
}


