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
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // MARK: --- Local State
    @State private var selectedPaymentMethod: PaymentMethod = .unknown
    @State private var statementDate = Date()
    @State private var endingBalance: String = ""
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    // MARK: --- Validation Computed Properties
    private var isPaymentMethodValid: Bool {
        selectedPaymentMethod != .unknown
    }

    private var isStatementDateValid: Bool {
        statementDate <= Date()
    }

    private var isAccountingPeriodValid: Bool {
        let today = Date()
        let currentYear = Calendar.current.component(.year, from: today)
        let currentMonth = Calendar.current.component(.month, from: today)
        return selectedYear < currentYear || (selectedYear == currentYear && selectedMonth <= currentMonth)
    }

    private var isEndingBalanceValid: Bool {
        Decimal(string: endingBalance) != nil
    }

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
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            headerView
            formGrid
            Divider()
            footerButtons
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 320)
    }
}

// MARK: --- Subviews
extension NewReconciliationView {
    
    private var headerView: some View {
        Text("New Reconciliation")
            .font(.title2)
            .bold()
    }
    
    private var formGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            
            GridRow {
                Text("Payment Method:")
                    .frame(width: 140, alignment: .trailing)
                Picker("", selection: $selectedPaymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Text(method.description).tag(method)
                    }
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
                DatePicker("", selection: $statementDate, in: ...Date(), displayedComponents: .date)
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
    }
    
    private var footerButtons: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
            Button("Save") { saveReconciliation() }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
        }
    }
}

// MARK: --- Actions
extension NewReconciliationView {
    
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

// MARK: --- Preview
struct NewReconciliationView_Previews: PreviewProvider {
    static var previews: some View {
        NewReconciliationView()
    }
}
