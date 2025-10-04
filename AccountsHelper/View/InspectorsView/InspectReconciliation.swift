//
//  InspectReconciliation.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 03/10/2025.
//

import SwiftUI
import CoreData

struct InspectReconciliation: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    
    // MARK: --- Date Formatter
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    // MARK: --- Reconciliation
    private var reconciliation: Reconciliation? {
        guard let id = appState.selectedReconciliationID else { return nil }
        return try? viewContext.existingObject(with: id) as? Reconciliation
    }
    
    private var reconciliationGap: Decimal {
        (try? reconciliation?.reconciliationGap(in: viewContext)) ?? 0
    }
    
    private var isBalanced: Bool {
        reconciliationGap == 0
    }
    
    // MARK: --- Body
    var body: some View {
        GeometryReader { geo in
            if let rec = reconciliation {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Reconciliation Details")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 10)
                        
                        // Payment Method
                        HStack {
                            Text("Payment Method:")
                                .bold()
                            Text(rec.paymentMethod.description)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Accounting Period
                        HStack {
                            Text("Accounting Period:")
                                .bold()
                            Text(rec.accountingPeriod.displayStringWithOpening)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Balance
                        HStack {
                            Text("Balance:")
                                .bold()
                            Text("\(rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(rec.currency.description)")
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Statement Date
                        HStack {
                            Text("Statement Date:")
                                .bold()
                            Text(rec.statementDate != nil ? dateFormatter.string(from: rec.statementDate!) : "N/A")
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Balance Status
                        HStack {
                            Text("Status:")
                                .bold()
                            VStack(alignment: .leading) {
                                Text(isBalanced ? "Balanced ✅" : "Unbalanced ⚠️")
                                    .foregroundColor(isBalanced ? .green : .red)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Balance Status
                        if !isBalanced {
                            HStack {
                                Text("Out of balance amount: ")
                                    .bold()
                                
                                Text("\(reconciliationGap.formatted(.number.precision(.fractionLength(2)))) \(reconciliation?.currency.description ?? "")")
                                    .foregroundColor(.primary) // black text
                                
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            } else {
                Text("No Reconciliation Selected")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
}
