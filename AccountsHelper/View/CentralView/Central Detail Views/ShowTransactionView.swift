//
//  ShowTransactionView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import SwiftUI

// MARK: - ShowTransactionView
struct ShowTransactionView: View {
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Transaction Details")
                    .font(.title)

                // Using a grid for better alignment
                Grid(alignment: .leading, verticalSpacing: 10) {
                    GridRow {
                        Text("Timestamp:")
                        Text(transaction.timestamp?.formatted(date: .abbreviated, time: .standard) ?? "N/A")
                    }
                    GridRow {
                        Text("Transaction Date:")
                        Text(transaction.transactionDate?.formatted(date: .abbreviated, time: .standard) ?? "N/A")
                    }
                    GridRow {
                        Text("Category:")
                        Text(transaction.category.description )
                    }
                    GridRow {
                        Text("Currency:")
                        Text(transaction.currency.description )
                    }
                    GridRow {
                        Text("Debit/Credit:")
                        Text(transaction.debitCredit.description )
                    }
                    GridRow {
                        Text("Exchange Rate:")
                        Text(transaction.exchangeRate, format: .number.precision(.fractionLength(2)))
                    }
                    GridRow {
                        Text("Explanation:")
                        Text(transaction.explanation ?? "N/A")
                    }
                    GridRow {
                        Text("Payee:")
                        Text(transaction.payee ?? "N/A")
                    }
                    GridRow {
                        Text("Payer:")
                        Text(transaction.payer.description )
                    }
                    GridRow {
                        Text("Payment Method:")
                        Text(transaction.paymentMethod.description)
                    }
                    GridRow {
                        Text("Split Amount:")
                        Text(transaction.splitAmount, format: .number.precision(.fractionLength(2)))
                    }
                    GridRow {
                        Text("Transaction Amount:")
                        Text("\(transaction.txAmountCD)")
                    }
                    GridRow {
                        Text("Split Category:")
                        Text(transaction.splitCategory.description)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .toolbar {
            Button("Dismiss") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
    }
}
