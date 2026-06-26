//
//  AdjustCatgoryView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/02/2026.
//

import Foundation
import SwiftUI

struct AdjustCategoryView: View {

    // MARK: --- Passed in
    let transaction: Transaction

    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: --- State for fields
    @State private var amountText: String = ""
    @State private var category: Category = .unknown

    // MARK: --- Validation / Save
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // MARK: --- Body
    var body: some View {
        VStack(spacing: 16) {

            Text("Adjust Category")
                .font(.title2)
                .fontWeight(.semibold)

            // Amount
            HStack {
                Text("Amount:")
                    .frame(width: 80, alignment: .trailing)
                TextField("Enter amount", text: $amountText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .keyboardType(.decimalPad)
            }

            // Category
            LabeledPicker(label: "Category", selection: $category, isValid: true)

            // Error message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveAdjustment()
                }
                .keyboardShortcut(.defaultAction)
            }

        }
        .padding()
        .frame(minWidth: 400)
//        .onAppear {
//            category = .unknown
//        }
    }

    // MARK: --- Save
    private func saveAdjustment() {
        guard let amount = Decimal(string: amountText), amount != 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        let newTx = Transaction(context: viewContext)
        newTx.timestamp = Date()
        newTx.transactionDate = transaction.transactionDate
        newTx.txAmount = amount
        newTx.category = category
        newTx.account = transaction.account
        // link back to original via pairID - preserve semantics elsewhere (assumes pairID is UUID)
        // Do not mutate original; if pairID linking is desired, use pairing helpers elsewhere.

        do {
            try viewContext.save()
            appState.refreshInspector()
            dismiss()
        } catch {
            errorMessage = "Failed to save adjustment: \(error.localizedDescription)"
            showError = true
        }
    }
}
