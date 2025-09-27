//
//  ReconcileDetailView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

import Foundation

import SwiftUI
import CoreData

struct ReconcileDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var reconciliation: Reconciliation
    
    @State private var transactions: [Transaction] = []
    @State private var isBalanced: Bool = false
    @State private var reconciliationGap: Decimal = 9999
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Payment Method: \(reconciliation.paymentMethod.description)")
                Spacer()
                Text("Balance: \(reconciliation.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(reconciliation.currency.description)")
            }
            .padding(.horizontal)
            
            HStack {
                Text("Statement Date: \(reconciliation.statementDate ?? Date(), style: .date)")
                Spacer()
                Text(isBalanced ? "Balanced ✅" : "Unbalanced ⚠️")
                    .foregroundColor(isBalanced ? .green : .red)
                if !isBalanced {
                    Text("Out of balance amount: \(reconciliationGap)")
                }
            }
            .padding(.horizontal)
            
            
            Divider()
            
            List(transactions) { tx in
                HStack {
                    Text(tx.payee ?? "Unknown")
                    Spacer()
                    Text(tx.explanation ?? "")
                    Spacer()
                    Text("\(tx.txAmount.formatted(.number.precision(.fractionLength(2)))) \(tx.currency.description)")
                        .bold()
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
            
            Spacer()
        }
        .navigationTitle("Reconciliation Detail")
        .onAppear {
            loadTransactions()
        }
    }
    
    private func loadTransactions() {
        do {
            transactions = try reconciliation.fetchTransactions(in: context)
            reconciliationGap = (try? reconciliation.reconciliationGap(in: context)) ?? Decimal(99999)
            isBalanced = reconciliationGap == 0
        } catch {
            print("Failed to load transactions: \(error)")
            transactions = []
        }
    }
}
