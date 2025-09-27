//
//  NewReconciliationView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 27/09/2025.
//

import Foundation
import SwiftUI

// MARK: - New Reconciliation View
struct NewReconciliationView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPaymentMethod: PaymentMethod = .unknown
    @State private var statementDate = Date()
    @State private var endingBalance: String = ""
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    // Payment method must not be unknown
    private var isPaymentMethodValid: Bool {
        selectedPaymentMethod != .unknown
    }

    // Statement date not in the future
    private var isStatementDateValid: Bool {
        statementDate <= Date()
    }

    // Accounting period not in the future
    private var isAccountingPeriodValid: Bool {
        let today = Date()
        let currentYear = Calendar.current.component(.year, from: today)
        let currentMonth = Calendar.current.component(.month, from: today)
        return selectedYear < currentYear || (selectedYear == currentYear && selectedMonth <= currentMonth)
    }

    // Ending balance must be parseable (optionally allow zero)
    private var isEndingBalanceValid: Bool {
        Decimal(string: endingBalance) != nil
    }

    // Accounting period for this payment method not already entered
    private var isUniquePeriodValid: Bool {
        let period = AccountingPeriod(year: selectedYear, month: selectedMonth)
        let existing = try? Reconciliation.fetchOne(for: period, paymentMethod: selectedPaymentMethod, context: context)
        return existing == nil
    }

    private var canSave: Bool {
        isPaymentMethodValid &&
        isStatementDateValid &&
        isAccountingPeriodValid &&
        isEndingBalanceValid &&
        isUniquePeriodValid
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Reconciliation")
                .font(.title2)
                .bold()
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                
                
                GridRow {
                    Text("Payment Method:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.description).tag(method) }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isPaymentMethodValid ? Color.clear : Color.red, lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    GridRow {
                        Text("Statement Date:")
                            .frame(width: 140, alignment: .trailing)
                        DatePicker("Statement Date", selection: $statementDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isStatementDateValid ? Color.clear : Color.red, lineWidth: 1)
                            )
                    }
                    
                    GridRow {
                        Text("Accounting Period:")
                            .frame(width: 140, alignment: .trailing)
                        HStack {
                            let today = Date()
                            let currentYear = Calendar.current.component(.year, from: today)
                            let currentMonth = Calendar.current.component(.month, from: today)
                            
                            Picker("Month", selection: $selectedMonth) {
                                let maxMonth = selectedYear == currentYear ? currentMonth : 12
                                ForEach(1...maxMonth, id: \.self) { month in
                                    Text(DateFormatter().monthSymbols[month-1]).tag(month)
                                }
                            }
                            
                            Picker("Year", selection: $selectedYear) {
                                ForEach(2000...currentYear, id: \.self) { year in
                                    Text("\(year)").tag(year)
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isAccountingPeriodValid && isUniquePeriodValid ? Color.clear : Color.red, lineWidth: 1)
                            )
                    }
                    
                    
                    GridRow {
                        Text("Ending Balance:")
                            .frame(width: 140, alignment: .trailing)
                        TextField("0.00", text: $endingBalance)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isEndingBalanceValid ? Color.clear : Color.red, lineWidth: 1)
                            )
                    }
                }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { saveReconciliation() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 320)
    }
    
    private func saveReconciliation() {
        guard let balanceDecimal = Decimal(string: endingBalance) else { return }
        let period = AccountingPeriod(year: selectedYear, month: selectedMonth)
        do {
            _ = try Reconciliation.createNew(
                paymentMethod: selectedPaymentMethod,
                period: period,
                statementDate: statementDate,
                endingBalance: balanceDecimal,
                in: context
            )
            dismiss()
        } catch {
            print("Error creating reconciliation: \(error)")
        }
    }
}
