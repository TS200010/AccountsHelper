//
//  EditEndingBalanceView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 06/10/2025.
//

import Foundation
import CoreData
import SwiftUI

// MARK: --- Edit Ending Balance View
struct EditReconcilationView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    // MARK: --- State
    @State private var endingBalance: String = ""
    @State private var reconciliation: Reconciliation?
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            header
            formGrid
            Divider()
            actionButtons
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 160)
        .onAppear { loadReconciliation() }
    }
    
    // MARK: --- Header
    @ViewBuilder
    private var header: some View {
        if reconciliation != nil {
            Text("Edit Reconcilation")
                .font(.title2)
                .bold()
        } else {
            Text("No reconciliation selected")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: --- Form Grid
    @ViewBuilder
    private var formGrid: some View {
        if reconciliation != nil {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
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
    }
    
    // MARK: --- Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if reconciliation != nil {
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { saveEndingBalanceValue() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isEndingBalanceValid)
            }
        }
    }
    
    // MARK: --- Helpers
    private var isEndingBalanceValid: Bool {
        Decimal(string: endingBalance) != nil
    }
    
    private func loadReconciliation() {
        guard let selectedID = appState.selectedReconciliationID else { return }
        if let rec = try? context.existingObject(with: selectedID) as? Reconciliation {
            reconciliation = rec
            endingBalance = rec.endingBalance.string2f
        }
    }
    
    private func saveEndingBalanceValue() {
        guard let rec = reconciliation,
              let newBalance = Decimal(string: endingBalance) else { return }
        rec.endingBalance = newBalance
        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save ending balance: \(error)")
            context.rollback()
        }
    }
}

// MARK: --- Preview
struct EditReconcilationView_Previews: PreviewProvider {
    static var previews: some View {
        EditReconcilationView()
            .frame(width: 500, height: 200)
    }
}
