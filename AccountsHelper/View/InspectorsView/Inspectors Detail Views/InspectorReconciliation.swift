//
//  InspectorReconciliation.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 03/10/2025.
//

import SwiftUI
import CoreData

// MARK: --- InspectorReconciliation
struct InspectorReconciliation: View {
    
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
    
    // MARK: --- Reconciliation Accessors
    private var reconciliation: Reconciliation? {
        guard let id = appState.selectedReconciliationID else { return nil }
        return try? viewContext.existingObject(with: id) as? Reconciliation
    }
    
    private var reconciliationGap: Decimal {
        reconciliation?.reconciliationGap() ?? 0
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
                        
                        // MARK: --- Payment Method
                        HStack {
                            Text("Account:").bold()
                            Text(rec.account.description)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // MARK: --- Accounting Period
                        HStack {
                            Text("Accounting Period:").bold()
                            Text(rec.accountingPeriod.displayStringWithOpening)
                            Text("\(rec.accountingPeriod.month)/")
                            Text("\(rec.accountingPeriod.year)")
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // MARK: --- Balance
                        HStack {
                            Text("Balance:").bold()
                            Text("\(rec.endingBalance.formattedAsCurrency(rec.currency))")
//                            Text("\(rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(rec.currency.description)")
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // MARK: --- Statement Date
                        HStack {
                            Text("Statement Date:").bold()
                            Text(rec.statementDate.map { dateFormatter.string(from: $0) } ?? "N/A")
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // MARK: --- Balance Status
                        HStack {
                            Text("Status:").bold()
                            HStack(spacing: 4) {
                                if isBalanced {
                                    Text("Balanced").foregroundColor(.green)
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.title3)
                                } else {
                                    Text("Unbalanced").foregroundColor(.red)
                                    Image(systemName: "exclamationmark.triangle.fill\n").foregroundColor(.red).font(.title3)
                                    Text("\(reconciliationGap)")
                                }
                            }
                            .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // MARK: --- Out of Balance Amount
                        if !isBalanced {
                            HStack {
                                Text("Out of balance amount:").bold()
                                Text("\(reconciliationGap.formattedAsCurrency(rec.currency))")
//                                Text("\(reconciliationGap.formatted(.number.precision(.fractionLength(2)))) \(rec.currency.description)")
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        // MARK: --- Closed Status
                        HStack {
                            Text("Closed:").bold()
                            HStack(spacing: 4) {
                                if rec.closed {
                                    Text("Closed").foregroundColor(.blue)
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.title3)
                                } else {
                                    Text("Not Closed").foregroundColor(.red)
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.title3)
                                }
                            }
                            .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
                .id(appState.inspectorRefreshTrigger)
                
            } else {
                // No reconciliation selected
                Text("No Reconciliation Selected")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
}
