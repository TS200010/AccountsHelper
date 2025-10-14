//
//  AccountStatementView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/10/2025.
//

/*
 import Foundation
 import SwiftUI
 import CoreData
 import ItMkLibrary
 
 // MARK: --- AccountStatementView
 struct AccountStatementView: View {
 
 // MARK: --- Environment
 @Environment(\.managedObjectContext) private var viewContext
 
 // MARK: --- Injected Properties
 let paymentMethod: PaymentMethod
 let selectedAccountingPeriod: AccountingPeriod?
 
 // MARK: --- FetchRequest
 @FetchRequest private var transactions: FetchedResults<Transaction>
 
 // MARK: --- State
 @State private var transactionsToDelete: Set<NSManagedObjectID> = []
 
 // MARK: --- Init
 init(paymentMethod: PaymentMethod, period: AccountingPeriod? = nil) {
 self.paymentMethod = paymentMethod
 self.selectedAccountingPeriod = period
 
 // Build predicate
 let predicate: NSPredicate? = {
 var predicates: [NSPredicate] = [
 NSPredicate(format: "paymentMethodCD == %@", NSNumber(value: paymentMethod.rawValue))
 ]
 if let period = period,
 let rec = try? Reconciliation.fetchOne(for: period, paymentMethod: paymentMethod, context: PersistenceController.shared.container.viewContext) {
 let start = rec.transactionStartDate as NSDate
 let end = rec.transactionEndDate as NSDate
 predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start, end))
 }
 return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
 }()
 
 _transactions = FetchRequest(
 sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
 predicate: predicate
 )
 }
 
 // MARK: --- Derived Rows
 private var statementRows: [TransactionRow] {
 var rows = transactions.map { TransactionRow(transaction: $0) }
 
 // Compute running balance
 var balance: Decimal = 0
 if let period = selectedAccountingPeriod,
 let previousRec = try? Reconciliation.fetchPrevious(
 for: paymentMethod,
 before: period.startDate,  // <-- use the start of the period
 context: viewContext
 ) {
 balance = previousRec.endingBalance
 }
 
 for i in 0..<rows.count {
 rows[i].runningBalance = balance - rows[i].transaction.txAmount
 balance = rows[i].runningBalance
 }
 
 return rows
 }
 
 // MARK: --- Body
 var body: some View {
 VStack(spacing: 0) {
 Text("Statement for \(paymentMethod.description)")
 .font(.headline)
 .padding()
 
 statementTable
 }
 #if os(macOS)
 .font(.custom("SF Mono Medium", size: 14))
 #else
 .font(.custom("SF Mono Medium", size: 15))
 #endif
 .frame(minHeight: 300)
 }
 }
 
 // MARK: --- Subviews & Helpers
 extension AccountStatementView {
 
 private var statementTable: some View {
 Table(statementRows) {
 TableColumn("Date") { row in
 Text(row.transactionDate)
 }
 .width(min: 90, ideal: 100, max: 150)
 
 TableColumn("Payee") { row in
 Text(row.payee)
 }
 .width(min: 50, ideal: 100, max: 200)
 
 TableColumn("Category") { row in
 Text(row.category)
 }
 .width(min: 80, ideal: 100, max: 150)
 
 TableColumn("Amount") { row in
 Text(row.txAmount)
 .frame(maxWidth: .infinity, alignment: .trailing)
 }
 .width(min: 100, ideal: 120, max: 150)
 
 TableColumn("Running Balance") { row in
 Text(row.runningBalance.formattedAsCurrency(row.transaction.currency))
 .frame(maxWidth: .infinity, alignment: .trailing)
 }
 .width(min: 120, ideal: 130, max: 150)
 }
 .tableStyle(.inset)
 }
 }
 */

