//
//  BrowseTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import Foundation
import SwiftUI
import CoreData
import ItMkLibrary
#if os(macOS)
import AppKit
import PrintingKit
typealias UIRectCorner = CACornerMask
#else
import UIKit
#endif


// MARK: --- BrowseTransactionsMode
enum BrowseTransactionsMode {
    case generalBrowsing
    case reconciliationAssignmentBrowsing
}

// MARK: --- To work aroound a SwiftUI bug
fileprivate func safeUIUpdate(_ action: @escaping () -> Void) {
    action()
//    DispatchQueue.main.async {
//        withAnimation(.none) {
//            action()
//        }
//    }
}

// MARK: --- RectCorner OptionSet
struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomLeft  = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}


// MARK: --- SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, currency, debitCredit, exchangeRate,
         payee, payer, account, reconciliation, transactionDate, txAmount

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .category:        return "folder"
        case .currency:        return "dollarsign.circle"
        case .debitCredit:     return "arrow.left.arrow.right"
        case .exchangeRate:    return "chart.line.uptrend.xyaxis"
        case .account:   return "creditcard"
        case .payee:           return "person"
        case .payer:           return "person.crop.circle"
        case .reconciliation:  return "checkmark.seal"
        case .transactionDate: return "calendar"
        case .txAmount:        return "sum"
        }
    }

    var title: String {
        switch self {
        case .category:        return "Category"
        case .currency:        return "Currency"
        case .debitCredit:     return "Debit/Credit"
        case .exchangeRate:    return "Fx"
        case .payee:           return "Payee"
        case .payer:           return "Payer"
        case .account:   return "Account"
        case .reconciliation:  return "Reconciliation"
        case .transactionDate: return "Date"
        case .txAmount:        return "Amount"
        }
    }

    fileprivate func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:        return row.category
        case .currency:        return row.currency
        case .debitCredit:     return row.debitCredit
        case .exchangeRate:    return row.exchangeRate
        case .payee:           return row.payee
        case .payer:           return row.payer
        case .account:         return row.account
        case .reconciliation:  return row.reconciliationPeriod
        case .transactionDate: return row.transactionDate
        case .txAmount:        return row.txAmount
        }
    }
}

// MARK: --- BrowseTransactionsView
struct BrowseTransactionsView: View {
    
    // MARK: --- Passed in
    let mode: BrowseTransactionsMode
//    let predicateIn: NSPredicate?
    
    // MARK: --- Computed Properties
    var showReconciliationFigures: Bool { mode == .reconciliationAssignmentBrowsing }
    var allowSelection:   Bool { mode == .reconciliationAssignmentBrowsing }
    var allowFiltering:   Bool { mode == .generalBrowsing}
    private var canActivateSelection: Bool {
        guard let rec = selectedReconciliation else { return false }
        return !rec.closed
    }

    // MARK: --- Environment
    @Environment(\.managedObjectContext) internal var viewContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) internal var appState
    @AppStorageEnum("showCurrencySymbols", defaultValue: .always) var showCurrencySymbols: ShowCurrencySymbolsEnum
    

    // MARK: --- State
    // Focus State
    @FocusState private var focusedRowIndex: Int?
    // Sort State
    @State private var ascending: Bool = true
    @State private var sortColumn: SortColumn = .transactionDate
    // Merge State
    @State private var mergeCandidates: [Transaction] = []
    // Selection State
    @State private var selectedTransaction: Transaction?
    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var lastClickedRowIndex: Int? = nil
    // Dialogs etc State
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTransactionView = false
    @State private var showMergeSheet = false
    // Delete State
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    // Filter State
    @State private var selectedAccountingPeriod: AccountingPeriod? = nil
    @State private var selectedAccount: ReconcilableAccounts? = nil
    // Column Width State
    #if os(macOS)
    @State private var availableWidth: CGFloat = 0
    @State private var scaledColumnWidths: [String: CGFloat] = [:]
    @State private var columnWidths: [String: CGFloat] = [
        "Account": 80,
        "Date": 100,
        "✓": 5,
        "Amount": 130,
        "Balance": 130,
        "Fx": 60,
        "Category": 80,
        "Split": 200,
        "Payee": 300,
        "Reconciliation": 60,
        "Link": 50
    ]
    #endif
    // Checked Selection State
    @State private var selectionActive: Bool = false
    // Running Totals
    private var checkedTotal: Decimal {  positiveCheckedTotal + negativeCheckedTotal }
    @State private var positiveCheckedTotal: Decimal = 0
    @State private var negativeCheckedTotal: Decimal = 0

    
    // MARK: --- Constants
    private let macOSRowHeight: CGFloat = 28
    
    // MARK: --- CoreData
    @FetchRequest internal var transactions: FetchedResults<Transaction>
//    @FetchRequest(sortDescriptors: []) private var reconciliations: FetchedResults<Reconciliation>

    var selectedReconciliation: Reconciliation? {
        if let id = appState.selectedReconciliationID {
            return reconciliations.first { $0.objectID == id }
        }
        return nil
    }

    // MARK: --- Initialiser
    init(predicate: NSPredicate? = nil, mode: BrowseTransactionsMode ) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
            predicate: predicate
        )
//        self.predicateIn = predicate
        self.mode = mode
    }
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Reconciliation.periodYear, ascending: false),
            NSSortDescriptor(keyPath: \Reconciliation.periodMonth, ascending: false)
        ],
        animation: .default
    )
    
    private var reconciliations: FetchedResults<Reconciliation>
    
    private var accountingPeriods: [AccountingPeriod] {
        var uniquePeriods = Set<AccountingPeriod>()
        for rec in reconciliations {
            uniquePeriods.insert(rec.accountingPeriod)
        }
        return Array(uniquePeriods).sorted(by: {
            ($0.year, $0.month) > ($1.year, $1.month)
        })
    }
    
   
    private func updateRunningTotals() {
        guard allowSelection else { return } // Do nothing if selection Not allowed. We have no checked total.
//        checkedTotal = transactions.filter { $0.checked }.map { $0.txAmountInGBP }.reduce(0, +)
//        checkedTotal = transactions.filter { $0.reconciliation == appState.selectedReconciliationID }.map { $0.txAmountInGBP }.reduce(0, +)
//        checkedTotal = selectedReconciliation?.sumInNativeCurrency() ?? 0
        negativeCheckedTotal = selectedReconciliation?.sumNegativeAmountsInNativeCurrency() ?? 0
        positiveCheckedTotal = selectedReconciliation?.sumPositiveAmountsInNativeCurrency() ?? 0
    }

    // MARK: --- Derived Rows
    private var transactionRows: [TransactionRow] {
        transactions.map { TransactionRow(transaction: $0) }
    }

    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            workingToolbar
            transactionsTable
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusBar
        }
        .onAppear { updateRunningTotals() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarItems }
        .onChange(of: selectedAccountingPeriod) { _, _ in
            safeUIUpdate {
                refreshFetchRequest()
            }
        }
        .onChange(of: selectedAccount) { _, _ in
            safeUIUpdate {
                refreshFetchRequest()
            }
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Selected", role: .destructive) {
                deleteTransactions(with: transactionsToDelete)
            }
        } message: {
            Text("This action cannot be undone (unless you press Undo).")
        }
#if os(iOS)
        .sheet(isPresented: $showingEditTransactionView) {
            Text("EDIT HERE\(String(describing: selectedTransactionIDs.first))")
            if selectedTransactionIDs.first != nil {
                AddOrEditTransactionView(transactionID: selectedTransactionIDs.first, context: viewContext )
            } else {
                Text("No transaction selected")
            }
        }
#endif
    }
}

// MARK: --- Subviews & Helpers
extension BrowseTransactionsView {

    // MARK: --- ContextMenu
    @ViewBuilder
    private func contextMenu(for row: TransactionRow) -> some View {
        
        if selectedTransactionIDs.contains(row.id) {
            
            if selectedTransactionIDs.count == 1 {
                Button("Edit Transaction") {
                    safeUIUpdate { selectedTransactionIDs = [row.id] }
                    appState.selectedTransactionID = row.id
                    appState.pushCentralView(.editTransaction(existingTransaction: row.transaction))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
            }
            
            if selectedTransactionIDs.count == 2 {
                Button("Merge Transactions") {
                    mergeCandidates = transactions.filter { selectedTransactionIDs.contains($0.objectID) }
                    appState.pushCentralView(.mergeTransactionsView(mergeCandidates))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
                Divider()
            }
            
            Button(role: .destructive) {
                safeUIUpdate {
                    transactionsToDelete = selectedTransactionIDs
                    showingDeleteConfirmation = true
                }
            } label: {
                Label("Delete Transaction(s)", systemImage: "trash")
            }
            .disabled(anySelectedTransactionClosed)
        }
    }

    // MARK: --- MultiLineTableCell
    @ViewBuilder
    private func multiLineTableCell(_ content: String, for row: TransactionRow, alignment: Alignment = .leading) -> some View {
        HStack {
            if alignment == .trailing { Spacer() }
            Text(content)
                .foregroundColor(
                    selectedTransactionIDs.contains(row.id)
                    ? .white // selected row text
                    : (row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
                )
                .opacity((selectionActive && row.checked) ? 0.5 : 1.0)
                .lineLimit(2)
                .truncationMode(.tail)
            if alignment == .leading { Spacer() }
        }
        .padding(.leading, alignment == .trailing ? 0 : 6)
        .padding(.trailing, alignment == .trailing ? 6 : 0)
        .frame(maxWidth: .infinity,
               alignment: alignment == .trailing ? .trailing : .leading)
//        .padding(.leading, 6)
//        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TableCell
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow, alignment: Alignment = .leading) -> some View {
        HStack {
            if alignment == .trailing { Spacer() }
            Text(content)
                .foregroundColor(
                    selectedTransactionIDs.contains(row.id)
                    ? .white // selected row text
                    : (row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
                )
            #if os(macOS)
                .opacity((selectionActive && row.checked) ? 0.5 : 1.0)
                .lineLimit(1)
                .truncationMode(.tail)
            #else
                .lineLimit(2)
            #endif
            if alignment == .leading { Spacer() }
        }
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TransactionsTable
    private var transactionsTable: some View {
        #if os(macOS)
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Color.clear // or any invisible view to attach `.onAppear` / `.onChange`
                    .onAppear {
                        availableWidth = width
                        // Load saved widths
                        if let saved = UserDefaults.standard.dictionary(forKey: gColumnWidthsKey) as? [String: Double] {
                            columnWidths = saved.mapValues { CGFloat($0) }
                        }
                        updateScaledWidths(for: availableWidth)
                    }
                    .onChange(of: width) { _, newWidth in
                        availableWidth = newWidth
                        updateScaledWidths(for: newWidth)
                    }
                
                VStack(spacing: 0) {
                    // --- Header Row
                    ZStack{
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(white: 0.80)) // slightly darker
                            .frame(height: macOSRowHeight) // force exact row height
                            .padding(.leading, 8)
                            .if(gViewCheck) { view in view.border(.orange) }
                        
                        HStack(spacing: 0) {
                            TableHeaderCell("Account", width: 80)
                                .frame(width: scaledColumnWidths["Account"] ?? 80)
                                .if( gViewCheck ) { view in view.border( .green )}
                            TableHeaderCell("Date", width: 100)
                                .frame(width: scaledColumnWidths["Date"] ?? 100)
                            TableHeaderCell("✓", width: 5)
                                .frame(width: scaledColumnWidths["✓"] ?? 5)
                            TableHeaderCell("Link", width: 50)
                                .frame(width: scaledColumnWidths["Link"] ?? 50)
                            TableHeaderCell("Reconciliation", width: 60)
                                .frame(width: scaledColumnWidths["Reconciliation"] ?? 60)
                            TableHeaderCell("Amount", width: 130)
                                .frame(width: scaledColumnWidths["Amount"] ?? 130)
                            TableHeaderCell("Payee", width: 100)
                                .frame(width: scaledColumnWidths["Payee"] ?? 100)
                            TableHeaderCell("Balance", width: 130)
                                .frame(width: scaledColumnWidths["Balance"] ?? 130)
                            TableHeaderCell("Fx", width: 60)
                                .frame(width: scaledColumnWidths["Fx"] ?? 60)
                            TableHeaderCell("Category", width: 80)
                                .frame(width: scaledColumnWidths["Category"] ?? 80)
                            TableHeaderCell("Split", width: 200)
                                .frame(width: scaledColumnWidths["Split"] ?? 200)

                        }
                        .if( gViewCheck ) { view in view.border( .cyan )}
                    }
                    .if( gViewCheck ) { view in view.border( .blue )}
                    
//                  --- Rows
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredTransactionRows.enumerated()), id: \.element.id) { index, row in
                                TransactionRowView(
                                    row: row,
                                    selectedTransactionIDs: $selectedTransactionIDs,
                                    anySelectedTransactionClosed: anySelectedTransactionClosed,
                                    appState: appState,
                                    index: index
                                )
                                .focusable(true)
//                                .focusRing(.none) // Disable blue focusRing
                                .focused($focusedRowIndex, equals: index)
                                .onTapGesture { focusedRowIndex = index }
                                .onMoveCommand { direction in
                                    switch direction {
                                    case .up:
                                        if let current = focusedRowIndex, current > 0 {
                                            let newIndex = current - 1
                                            focusedRowIndex = newIndex
                                            lastClickedRowIndex = newIndex
                                            DispatchQueue.main.async {
                                                selectedTransactionIDs = [filteredTransactionRows[newIndex].id]
                                            }
                                        }
                                    case .down:
                                        if let current = focusedRowIndex,
                                           current < filteredTransactionRows.count - 1 {
                                            let newIndex = current + 1
                                            focusedRowIndex = newIndex
                                            lastClickedRowIndex = newIndex
                                            DispatchQueue.main.async {
                                                selectedTransactionIDs = [filteredTransactionRows[newIndex].id]
                                            }
                                        }
                                    default: break
                                    }
                                }
                            }
                        }
                    }
                    .frame(minHeight: 300)
                }
                .onAppear {
                    updateScaledWidths(for: availableWidth)
                }
                .onChange(of: availableWidth) { _, newWidth in
                    updateScaledWidths(for: newWidth)
                }
                // --- Constrain VStack to the width of the available window
                .frame(minWidth: proxy.size.width, alignment: .leading)
                .if(gViewCheck) { view in view.border(.red).padding(.leading, 0) }
            }
            .contextMenu { SortContextMenu() }
            .onChange(of: selectedTransactionIDs) { _, newSelection in
                safeUIUpdate {
                    if let firstID = newSelection.first {
                        appState.selectedTransactionID = firstID
                        appState.selectedInspectorView = .viewTransaction
                    } else {
                        selectedTransaction = nil
                        appState.selectedTransactionID = nil
                    }
                }
            }
        }
        #else
        // iOS version using standard SwiftUI Table
        Table(filteredTransactionRows, selection: $selectedTransactionIDs) {
            TableColumn("Transaction") { row in
                tableCell(row.iOSRowForDisplay, for: row)
                    .onTapGesture {
                        safeUIUpdate {
                            selectedTransactionIDs = [row.id]
                            appState.selectedTransactionID = row.id
                        }
                    }
            }
        }
        .font(.custom("SF Mono Medium", size: 15))
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { SortContextMenu() }
        #endif
    }
    
    // MARK: --- UpdateScaledWidths
#if os(macOS)
    private func updateScaledWidths(for availableWidth: CGFloat) {
        let minWidth: CGFloat = 60
        let totalRequested = columnWidths.values.reduce(0, +)

        // Scale to fit availableWidth proportionally
        // 16 is to not entirely fill available space
        let scaleFactor = (availableWidth - 50) / totalRequested
        scaledColumnWidths = columnWidths.mapValues { max(minWidth, $0 * scaleFactor) }
    }
#endif



    // MARK: --- ResizeColumn
#if os(macOS)
    private func resizeColumn(title: String, delta: CGFloat) {
        guard let currentWidth = columnWidths[title], availableWidth > 0 else { return }

        let minWidth: CGFloat = 60
        let newWidth = max(minWidth, currentWidth + delta)
        columnWidths[title] = newWidth

        // Total width after resize
        let totalWidth = columnWidths.values.reduce(0, +)

        // If total exceeds availableWidth, shrink flexible columns
        if totalWidth > availableWidth {
            var remainingExcess = totalWidth - availableWidth

            // Flexible columns excluding the dragged one
            let flexibleColumns = columnWidths.keys.filter { $0 != title }

            for key in flexibleColumns.reversed() { // shrink from right
                guard let width = columnWidths[key] else { continue }
                let shrinkable = max(width - minWidth, 0)
                if shrinkable >= remainingExcess {
                    columnWidths[key] = width - remainingExcess
                    remainingExcess = 0
                    break
                } else {
                    columnWidths[key] = width - shrinkable
                    remainingExcess -= shrinkable
                }
            }

            // Clamp dragged column if still over
            if remainingExcess > 0 {
                columnWidths[title] = max(minWidth, newWidth - remainingExcess)
            }
        }

        scaledColumnWidths = columnWidths
        // Save
        UserDefaults.standard.set(columnWidths.mapValues { Double($0) }, forKey: gColumnWidthsKey)
    }
    #endif

    // MARK: --- TransactionRowView
    @ViewBuilder
    private func TransactionRowView(
        row: TransactionRow,
        selectedTransactionIDs: Binding<Set<NSManagedObjectID>>,
        anySelectedTransactionClosed: Bool,
        appState: AppState,
        index: Int
    ) -> some View {
        #if os(macOS)
        ZStack {                                     // Wrap so background can fill full width
            rowBackground(for: index, row: row)
            HStack(spacing: 0) {
                tableCell(row.account, for: row)
                    .frame(width: scaledColumnWidths["Account"] ?? 80)
                    .if( gViewCheck ) { view in view.border( .yellow )}
                
                tableCell(row.transactionDate, for: row)
                    .frame(width: scaledColumnWidths["Date"] ?? 100)
                
                HStack {
                    Spacer(minLength: 0)
                    Toggle("", isOn: Binding(
                        get: { row.checked },
                        set: { newValue in
                            guard selectionActive else { return }
                            row.checked = newValue
                            if let recID = appState.selectedReconciliationID,
                               let rec = reconciliations.first(where: { $0.objectID == recID }) {
                                
                                if newValue {
                                    // Assign transaction to reconciliation
                                    rec.addToTransactions(row.transaction)
                                    //                                    row.transaction.reconciliation = rec
                                } else {
                                    // Remove only if it currently belongs to this reconciliation
                                    if row.transaction.reconciliation == rec {
                                        rec.removeFromTransactions(row.transaction)
                                        //                                        row.transaction.reconciliation = nil
                                    }
                                }
                                
                                // Save changes and update totals
                                try? viewContext.save()
                                updateRunningTotals()
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .disabled(!allowSelection || row.transaction.closed)
                    .labelsHidden()
                    .frame(width: 20, height: 20)
                    Spacer(minLength: 0)
                }
                .frame(width: scaledColumnWidths["✓"] ?? 5)
                .disabled(row.transaction.closed)
                
                Group {
                    if row.transaction.pairID == nil {
                        // empty
                        Text("-")
                    } else if !row.transaction.isPairValid(in: viewContext) {
                        // pairID present but invalid (not exactly 2 members)
//                        Text("X")
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                    } else if row.transaction.linkedTransaction(in: viewContext) != nil {
                        Image(systemName: "link.circle")
                            .font(.system(size: 14, weight: .regular))
                    } else {
                        // Probably never get here
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.yellow)
                    }
                }
                .frame(width: scaledColumnWidths["Link"] ?? 50, height: macOSRowHeight, alignment: .center)
                .padding(.horizontal, 4)
                
                tableCell(row.reconciliationPeriodShortDescription, for: row)
                    .frame(width: scaledColumnWidths["Reconciliation"] ?? 60)
            
                multiLineTableCell( row.transaction.totalAmountDualCurrencyAsString(withSymbol: showCurrencySymbols), for: row, alignment: .trailing )
                    .multilineTextAlignment(.trailing)
                    .frame(width: scaledColumnWidths["Amount"] ?? 130)
                
                tableCell(row.payee, for: row)
                    .frame(width: scaledColumnWidths["Payee"] ?? 100)
                
                tableCell(
                    AmountFormatter.anyAmountAsString(
                        amount: row.runningBalance,
                        currency: .GBP,
                        withSymbol: showCurrencySymbols
                    ), for: row, alignment: .trailing
                )
                    .frame(width: scaledColumnWidths["Balance"] ?? 130)
                
                tableCell(row.exchangeRate, for: row)
                    .frame(width: scaledColumnWidths["Fx"] ?? 60)
                
                tableCell(row.category, for: row)
                    .frame(width: scaledColumnWidths["Category"] ?? 80)
                
                multiLineTableCell( row.transaction.splitAmountAndCategoryAsString(withSymbol: showCurrencySymbols), for: row, alignment: .leading )
                    .frame(width: scaledColumnWidths["Split"] ?? 200)
                

            }
            .padding(.leading, 16)
            .contentShape(Rectangle())
        }
        .if( gViewCheck ) { view in view.border( .green )}
        .onTapGesture {
            #if os(macOS)
            if selectionActive {
                guard let recID = appState.selectedReconciliationID,
                      let rec = reconciliations.first(where: { $0.objectID == recID }) else { return }

                if row.transaction.reconciliation == rec {
                    // Unassign transaction from reconciliation
                    row.transaction.reconciliation = nil
                } else {
                    // Assign transaction to reconciliation
                    row.transaction.reconciliation = rec
                }

                try? viewContext.save()
                updateRunningTotals()  // This now uses reconciliation as the source of truth
                
//                // Toggle only the checkbox when selection mode is active
//                row.checked.toggle()
//                row.transaction.checked = row.checked
//                try? viewContext.save()
            } else {
                safeUIUpdate {
                    let modifiers = NSEvent.modifierFlags
                    let rowIndex = index
                    
                    if modifiers.contains(.command) {
                        // Cmd-click toggles selection
                        if selectedTransactionIDs.wrappedValue.contains(row.id) {
                            selectedTransactionIDs.wrappedValue.remove(row.id)
                        } else {
                            selectedTransactionIDs.wrappedValue.insert(row.id)
                        }
                        lastClickedRowIndex = rowIndex
                    } else if modifiers.contains(.shift), let lastIndex = lastClickedRowIndex {
                        // Shift-click selects range
                        let minIndex = min(lastIndex, rowIndex)
                        let maxIndex = max(lastIndex, rowIndex)
                        let rangeIDs = filteredTransactionRows[minIndex...maxIndex].map { $0.id }
                        selectedTransactionIDs.wrappedValue.formUnion(rangeIDs)
                    } else {
                        // Regular click selects single row
                        selectedTransactionIDs.wrappedValue = [row.id]
                        lastClickedRowIndex = rowIndex
                    }
                }
            }
            #else
            safeUIUpdate { selectedTransactionIDs.wrappedValue = [row.id] }
            #endif
        }

        .contextMenu { contextMenu(for: row) }
        #else
        tableCell(row.iOSRowForDisplay, for: row)
            .contentShape(Rectangle())
            .onTapGesture {
                safeUIUpdate { selectedTransactionIDs.wrappedValue = [row.id] }
            }
            .contextMenu { contextMenu(for: row) }
        #endif
    }


    // MARK: --- TableHeaderCell (macOS only)
    #if os(macOS)
    @ViewBuilder
    private func TableHeaderCell(_ title: String, width: CGFloat) -> some View {
        let handleWidth: CGFloat = 4
        
        HStack(spacing: 0) {
            // --- Column title
            Text(title)
                .padding(.leading, 6)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.custom("SF Mono Medium", size: 14))
                .frame(width: (scaledColumnWidths[title] ?? width) - handleWidth, height: macOSRowHeight, alignment: .leading)
//                .background(Color.gray.opacity(0.1))
//                .border(Color.gray.opacity(0.3), width: 0.5)
            
            // --- Drag handle
            Rectangle()
                .foregroundColor(.white)
                .frame(width: handleWidth, height: macOSRowHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
//                            let val2 = (value.translation.width > 0 ? 1 : -1 )
//                            resizeColumn(title: title, delta: CGFloat(val2))
                            resizeColumn(title: title, delta: value.translation.width)
                        }
                )
                .onHover { hovering in
                    NSCursor.resizeLeftRight.set()
                    if !hovering { NSCursor.arrow.set() }
                }
        }
        .frame(width: scaledColumnWidths[title] ?? width, height: macOSRowHeight)
    }
#endif

    // MARK: --- SortContextMenu
    @ViewBuilder
    private func SortContextMenu() -> some View {
#if os(iOS)
        Button {
            //            appState.selectedTransactionID = selectedTransactionIDs.first
            showingEditTransactionView = true
        } label: {
            Label("Edit", systemImage: "circle.badge.xmark")
        }
#endif
        ForEach(SortColumn.allCases) { column in
            Button {
                updateSortColumn(column)
            } label: {
                Label("Sort by \(column.title)", systemImage: column.systemImage)
            }
        }
    }

    // MARK: --- StatusBar
    private var statusBar: some View {
        HStack {
            Spacer()
            Text(selectedTransactionIDs.isEmpty
                 ? "Total Transactions: \(transactions.count)"
                 : "Selected: \(selectedTransactionIDs.count)")
        }
        .padding(8)
        .background(Color.ItMkPlatformWindowBackgroundColor)
    }

    // MARK: --- ToolbarItems
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem {
                Button(action: {
                    guard canActivateSelection || selectionActive else { return }
                    selectionActive.toggle()
                    if selectionActive {
                        selectedTransactionIDs.removeAll()
                    }
                }) {
                    Label(selectionActive ? "Done" : "Select", systemImage: selectionActive ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .foregroundColor(selectionActive ? .orange : .primary)
                }
                .disabled( !allowSelection )
                .opacity(allowSelection ? 1 : 0.5) // Manual opacity for this one TLDR
            }
            ToolbarItem {
                Button(role: .destructive) {
                    safeUIUpdate {
                        transactionsToDelete = selectedTransactionIDs
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selectedTransactionIDs.isEmpty)
            }
            ToolbarItem {
                Button { undoManager?.undo() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!(undoManager?.canUndo ?? false))
            }
            ToolbarItem {
                Button { undoManager?.redo() } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!(undoManager?.canRedo ?? false))
            }
            // MARK: --- Frint Menu
            ToolbarItem(placement: .automatic) {
                Button {
                    printTransactions()
                } label: {
                    Label("Print Transactions", systemImage: "printer")
                }
            }
            // MARK: --- Filter Menu
            ToolbarItem {
                Menu {
                    // Accounting Period Picker
                    Picker("Accounting Period", selection: $selectedAccountingPeriod) {
                        Text("All").tag(nil as AccountingPeriod?)
                        ForEach(uniqueAccountingPeriods, id: \.self) { period in
                            Text(period.displayStringWithOpening).tag(period as AccountingPeriod?)
                        }
                    }
                    
                    // Payment Method Picker
                    Picker("Account", selection: $selectedAccount) {
                        Text("All").tag(nil as ReconcilableAccounts?)
                        ForEach(ReconcilableAccounts.allCases, id: \.self) { method in
                            Text(method.description).tag(method as ReconcilableAccounts?)
                        }
                    }
                } label: {
                    Label("Filters", systemImage: "line.horizontal.3.decrease.circle")
                }
            }
        }
    }

    // MARK: --- Helpers
    private func updateSortColumn(_ column: SortColumn) {
        // Defer the change to avoid mutating the table's data while AppKit/SwiftUI
        // are mid-update (this avoids the NSIndexSet enumerateIndexesInRange crash).
        DispatchQueue.main.async {
            // Prevent SwiftUI animated diffs which sometimes cause internal indexset issues.
            withAnimation(.none) {
                if sortColumn == column {
                    ascending.toggle()
                } else {
                    sortColumn = column
                    ascending = true
                }
                safeUIUpdate {
                    selectedTransactionIDs.removeAll()
                }
            }
        }
    }

    private var anySelectedTransactionClosed: Bool {
        selectedTransactionIDs.contains { id in
            guard let tx = transactions.first(where: { $0.objectID == id }) else { return false }
            return tx.closed
        }
    }

    private func deleteTransactions(with ids: Set<NSManagedObjectID>) {
        viewContext.perform {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "self IN %@", ids)
            do {
                let transactionsToDelete = try viewContext.fetch(fetchRequest)
                let deletedObjectsData: [[String: Any?]] = transactionsToDelete.map { transaction in
                    let keys = Array(transaction.entity.attributesByName.keys)
                    return transaction.dictionaryWithValues(forKeys: keys)
                }
                transactionsToDelete.forEach { viewContext.delete($0) }
                try viewContext.save()
                safeUIUpdate {
                    selectedTransactionIDs.removeAll()
                }

                undoManager?.registerUndo(withTarget: viewContext) { context in
                    for data in deletedObjectsData {
                        let restored = Transaction(context: context)
                        for (key, value) in data {
                            restored.setValue(value, forKey: key)
                        }
                    }
                    try? context.save()
                    DispatchQueue.main.async {
                        appState.refreshInspector()
                    }
                }
                undoManager?.setActionName("Delete Transactions")
            } catch {
                print("Failed to delete transactions: \(error.localizedDescription)")
                viewContext.rollback()
            }
        }
    }
}

// MARK: --- FILTERING
extension BrowseTransactionsView {
    
    // MARK: --- BuildFilteredPredicate
    private func buildFilteredPredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []
        
        // --- Payment Method Filter
        if let method = selectedAccount {
            predicates.append(NSPredicate(format: "accountCD == %@", NSNumber(value: method.rawValue)))
        }
        
        // --- Accounting Period / Date Filter
        if let method = selectedAccount, let period = selectedAccountingPeriod {
            if let reconciliation = try? Reconciliation.fetchOne(for: period, account: method, context: viewContext) {
                let start = reconciliation.transactionStartDate as NSDate
                let end = reconciliation.transactionEndDate as NSDate
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start, end))
            }
        }
        
        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    
    // MARK: --- RefreshFetchRequest
    private func refreshFetchRequest() {
        safeUIUpdate {
            transactions.nsPredicate = buildFilteredPredicate()
        }
    }
    
    // MARK: --- WorkingToolbar
    private var workingToolbar: some View {
        
        // Compute checked totals as strings
        
        var checkedTotalAsString: String {
            return AmountFormatter.anyAmountAsString(amount: checkedTotal, currency: .GBP, withSymbol: showCurrencySymbols)
        }
        
        var positiveCheckedTotalAsString: String {
            return AmountFormatter.anyAmountAsString(amount: positiveCheckedTotal, currency: .GBP, withSymbol: showCurrencySymbols)
//            let total = transactions
//                .filter { $0.reconciliation == appState.selectedReconciliationID }
//                .map { $0.txAmountInGBP }
//                .filter { $0 > 0 }
//                .reduce(0, +)
//            return AmountFormatter.anyAmountAsString(amount: total, currency: .GBP, withSymbol: showCurrencySymbols)
        }

        var negativeCheckedTotalAsString: String {
            return AmountFormatter.anyAmountAsString(amount: negativeCheckedTotal, currency: .GBP, withSymbol: showCurrencySymbols)
//            let total = transactions
//                .filter { $0.reconciliation == appState.selectedReconciliationID }
//                .map { $0.txAmountInGBP }
//                .filter { $0 < 0 }
//                .reduce(0, +)
//            return AmountFormatter.anyAmountAsString(amount: total, currency: .GBP, withSymbol: showCurrencySymbols)
        }
        
        var openingBalanceAsString: String {
            guard
                let recID = appState.selectedReconciliationID,
                let rec = reconciliations.first(where: { $0.objectID == recID })
            else { return "" }
            return rec.openingBalanceAsString()
        }

        var reconciliationGapAsString: String {
            guard
                let recID = appState.selectedReconciliationID,
                let rec = reconciliations.first(where: { $0.objectID == recID })
            else { return "" }
            return rec.reconciliationGapAsString()
        }
        
        return HStack(spacing: 16) {
            
            // --- Filtering
            if allowFiltering {
                // --- Account Picker
                Picker("Account", selection: $selectedAccount) {
                    Text("All").tag(nil as ReconcilableAccounts?)
                    ForEach(ReconcilableAccounts.allCases.filter { $0 != .unknown }, id: \.self) { method in
                        Text(method.description).tag(method as ReconcilableAccounts?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                // --- Accounting Period Picker (only show if a payment method is selected)
                if let method = selectedAccount {
                    Picker("Period", selection: $selectedAccountingPeriod) {
                        Text("All").tag(nil as AccountingPeriod?)
                        
                        // Only show periods that have reconciliations for this method
                        ForEach(accountingPeriodsForAccount(method), id: \.self) { period in
                            Text(period.displayStringWithOpening).tag(Optional(period))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // --- Checked Total
            if showReconciliationFigures,
             let rec = selectedReconciliation {
                
                // Opening Balance
                Text("Opening:\n \(openingBalanceAsString)")
                    .fontWeight(.semibold)

                
                // Checked Total
//                Text("Checked total: \(rec.sumCheckedInNativeCurrencyAsString())")
                Text ("Checked total:\n \( checkedTotalAsString )")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                // Checked Positive
                Text("Checked positive:\n \( positiveCheckedTotalAsString )")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                // Checked Negative
                Text("Checked negative:\n \( negativeCheckedTotalAsString )")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                // Target / Ending Balance
                Text("Target:\n \(rec.endingBalanceAsString())")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                // Gap
                Text("Gap:\n \(reconciliationGapAsString)")
                    .fontWeight(.semibold)
//                    .foregroundColor(rec.reconciliationGap < 0 ? .red : .green)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.ItMkPlatformWindowBackgroundColor)
    }
    
    // MARK: --- Unique Accounting Periods
    private var uniqueAccountingPeriods: [AccountingPeriod] {
        let periods = transactions.compactMap { transaction -> AccountingPeriod? in
            guard let date = transaction.transactionDate else { return nil }
            let comps = Calendar.current.dateComponents([.year, .month], from: date)
            guard let year = comps.year, let month = comps.month else { return nil }
            return AccountingPeriod(year: year, month: month)
        }
        return Array(Set(periods)).sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year < rhs.year }
            return lhs.month < rhs.month
        }
    }
    
    // MARK: --- Accounting periods per payment method
    private func accountingPeriodsForAccount(_ method: ReconcilableAccounts) -> [AccountingPeriod] {
        let periods = reconciliations
            .filter { $0.account == method }
            .map { $0.accountingPeriod }
        return Array(Set(periods))
            .sorted { ($0.year, $0.month) > ($1.year, $1.month) }
    }
    
    // MARK: --- FilteredTransactionRows
    // This filters the Transactions that were passed in with whatever predicate was supplied
    private var filteredTransactionRows: [TransactionRow] {
        let predicate = buildFilteredPredicate()
        let allTransactions = Array(transactions)
        let filtered = predicate == nil ? allTransactions : allTransactions.filter { predicate!.evaluate(with: $0) }
        
        // Map to rows
        var rows = filtered.map { TransactionRow(transaction: $0) }
        
        // Sort rows
        rows.sort { lhs, rhs in
            switch sortColumn {
            case .transactionDate:
                guard let lDate = lhs.transaction.transactionDate,
                      let rDate = rhs.transaction.transactionDate else { return false }
                return ascending ? (lDate < rDate) : (lDate > rDate)
            case .txAmount:
                let lAmount = lhs.transaction.txAmountInGBP
                let rAmount = rhs.transaction.txAmountInGBP
                return ascending ? (lAmount < rAmount) : (lAmount > rAmount)
            default:
                if let l = sortColumn.stringKey(for: lhs),
                   let r = sortColumn.stringKey(for: rhs) {
                    let cmp = l.localizedCompare(r)
                    return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
                }
                return false
            }
        }
        
        // MARK: --- Compute running balances (GBP only)
        if let account = selectedAccount, sortColumn == .transactionDate {
            // Get previous reconciliation balance if available
            var balance: Decimal = 0
            if let previousRec = reconciliations
                .filter({ $0.account == account })
                .sorted(by: { ($0.periodYear, $0.periodMonth) > ($1.periodYear, $1.periodMonth) })
                .first {
                balance = previousRec.endingBalance
            }
            
            // Apply running balance
            for i in 0..<rows.count {
                rows[i].runningBalance = balance - rows[i].transaction.txAmountInGBP
                balance = rows[i].runningBalance
            }
        }
        
        return rows
    }
}

// MARK: --- VIEW HELPERS
extension BrowseTransactionsView {
    
    // Helper for the row background
    @ViewBuilder
    private func rowBackground(for index: Int, row: TransactionRow) -> some View {
#if os(macOS)
        let rowWidth = scaledColumnWidths.values.reduce(0, +)
        if selectionActive {
            // In selection mode, no row highlight
            Color.clear
                .frame(width: rowWidth, height: macOSRowHeight)
        } else {
            if selectedTransactionIDs.contains(row.id) {
                let prevSelected = index > 0 && selectedTransactionIDs.contains(filteredTransactionRows[index-1].id)
                let nextSelected = index < filteredTransactionRows.count-1 && selectedTransactionIDs.contains(filteredTransactionRows[index+1].id)
                if !prevSelected && !nextSelected {
                    // Single row selected — round all corners
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(.blue)
                        .frame(width: rowWidth, height: macOSRowHeight)
                } else if !prevSelected && nextSelected {
                    // Top row of multi-selection — round top corners only
                    Color.blue
                        .frame(width: rowWidth, height: macOSRowHeight)
                        .clipShape(RoundedCorner(corners: [.topLeft, .topRight], radius: 8))
                } else if prevSelected && !nextSelected {
                    // Bottom row of multi-selection — round bottom corners only
                    Color.blue
                        .frame(width: rowWidth, height: macOSRowHeight)
                        .clipShape(RoundedCorner(corners: [.bottomLeft, .bottomRight], radius: 8))
                } else {
                    // Middle row of multi-selection — no rounding
                    Color.blue
                        .frame(width: rowWidth, height: macOSRowHeight)
                }
            } else if index % 2 == 0 {
                Color.clear
                    .frame(width: rowWidth, height: macOSRowHeight)
            } else {
                Color.gray.opacity(0.05)
                    .frame(width: rowWidth, height: macOSRowHeight)
                
            }
        }
#else
        // TODO: Set to frame width
        let rowWidth:CGFloat = 0 // Not actuallty needed at the moment
        let iOSRowHeight: CGFloat = 40
        if index % 2 == 0 {
            Color.clear
                .frame(height: iOSRowHeight)
                .frame(maxWidth: .infinity) // fill the whole width
        } else {
            Color.gray.opacity(0.05)
                .frame(height: iOSRowHeight)
                .frame(maxWidth: .infinity) // fill the whole width
        }
#endif
    }
    
    // MARK: --- RoundedCorner
    struct RoundedCorner: Shape {
        var corners: RectCorner
        var radius: CGFloat
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let tl = corners.contains(.topLeft) ? radius : 0
            let tr = corners.contains(.topRight) ? radius : 0
            let bl = corners.contains(.bottomLeft) ? radius : 0
            let br = corners.contains(.bottomRight) ? radius : 0
            
            path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
            
            // Top edge
            path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            if tr > 0 {
                path.addArc(
                    center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false
                )
            }
            
            // Right edge
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
            if br > 0 {
                path.addArc(
                    center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false
                )
            }
            
            // Bottom edge
            path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
            if bl > 0 {
                path.addArc(
                    center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false
                )
            }
            
            // Left edge
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
            if tl > 0 {
                path.addArc(
                    center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            }
            
            path.closeSubpath()
            return path
        }
    }
}
