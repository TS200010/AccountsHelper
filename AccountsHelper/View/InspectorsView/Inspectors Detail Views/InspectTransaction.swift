//
//  InspectTransaction.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import SwiftUI
import CoreData
import Observation

// MARK: --- InspectTransaction
struct InspectTransaction: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: --- Selected Transaction
    var transaction: Transaction? {
        guard let id = appState.selectedTransactionID else { return nil }
        return try? viewContext.existingObject(with: id) as? Transaction
    }
    
    // MARK: --- Body
    var body: some View {
        GeometryReader { geo in
            if let transaction {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: --- Header
                        Text("Transaction Details")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 10)
                        
                        // MARK: --- General Section
//                        inspectorSection("General") {
//                            transactionRow("Timestamp:", transaction.timestamp?.formatted(date: .abbreviated, time: .standard) ?? "N/A")
//                            Divider()
//                            transactionRow("TX Date:", transaction.transactionDate?.formatted(date: .abbreviated, time: .standard) ?? "N/A")
//                        }
                        inspectorSection("General") {
                            transactionRow("Timestamp:", transaction.timestamp.map { dateOnlyFormatter.string(from: $0) } ?? "N/A")
                            Divider()
                            transactionRow("TX Date:", transaction.transactionDate.map { dateOnlyFormatter.string(from: $0) } ?? "N/A")
                        }
                        
                        // MARK: --- Categories Section
                        inspectorSection("Categories") {
                            transactionRow("Category:", transaction.category.description)
                            Divider()
                            transactionRow("Split Cat:", transaction.splitCategory.description)
                            Divider()
                            transactionRow("Rem Cat:", transaction.splitRemainderCategory.description)
                        }
                        
                        // MARK: --- Amounts Section
                        inspectorSection("Amounts") {
                            transactionRow("Currency:", transaction.currency.description)
                            Divider()
                            transactionRow("DR/CR:", transaction.debitCredit.description)
                            Divider()
                            transactionRow("Fx:", transaction.exchangeRateAsStringLong() ?? "N/A")
                            Divider()
                            transactionRow("Split Amt:", String(format: "%.2f", (transaction.splitAmount as NSDecimalNumber?)?.doubleValue ?? 0))
                            Divider()
                            transactionRow("Rem Amt:", String(format: "%.2f", (transaction.splitRemainderAmount as NSDecimalNumber?)?.doubleValue ?? 0))
                            Divider()
                            transactionRow("TX Amt:", String(format: "%.2f", (transaction.txAmount as NSDecimalNumber?)?.doubleValue ?? 0))
                            Divider()
                            transactionRow("Comm Amt:", String(format: "%.2f", (transaction.commissionAmount as NSDecimalNumber?)?.doubleValue ?? 0))
                            Divider()
                            transactionRow("Total in GBP:", String(format: "%.2f", (transaction.totalAmountInGBP as NSDecimalNumber?)?.doubleValue ?? 0))
                        }
                        
                        // MARK: --- Parties Section
                        inspectorSection("Parties") {
                            transactionRow("Payee:", transaction.payee ?? "N/A")
                            Divider()
                            transactionRow("Payer:", transaction.payer.description)
                            Divider()
                            transactionRow("Pmt Method:", transaction.paymentMethod.description)
                        }
                        
                        // MARK: --- Additional Info Section
                        inspectorSection("Additional Info") {
                            transactionRow("A/C Number:", transaction.accountNumber ?? "N/A")
                            Divider()
                            transactionRow("Address:", transaction.address ?? "N/A")
                            Divider()
                            transactionRow("Reference:", transaction.reference ?? "N/A")
                            Divider()
                            transactionRow("Extended", transaction.extendedDetails ?? "N/A")
                            Divider()
                            transactionRow("Explanation:", transaction.explanation ?? "N/A")
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial) // LiquidGlass effect
                    .cornerRadius(12)
                    .padding()
                }
                .id(appState.inspectorRefreshTrigger)
                
            } else {
                Text("No Transaction Selected")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.gray)
            }

        }
    }
    
    // MARK: --- Section Wrapper
    @ViewBuilder
    private func inspectorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial.opacity(0.5))
            .cornerRadius(8)
        }
        .padding(.vertical, 5)
    }
    
    // MARK: --- Row Helper
    @ViewBuilder
    private func transactionRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(.body, weight: .medium))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .trailing)
            Text(value)
                .font(.system(.body))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
