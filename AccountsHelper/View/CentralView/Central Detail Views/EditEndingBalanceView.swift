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
    
    // MARK: --- Local State
    @State private var endingBalance: String = ""
    @State private var reconciliation: Reconciliation?
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            if let rec = reconciliation {
                Text("Edit Reconcilation")
                    .font(.title2)
                    .bold()
                
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
                
                Divider()
                
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save") { saveEndingBalanceValue() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!isEndingBalanceValid)
                }
            } else {
                Text("No reconciliation selected")
                    .foregroundColor(.gray)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 160)
        .onAppear { loadReconciliation() }
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
