//
//  AddOrEditTransactionView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import SwiftUI
import CoreData
import ItMkLibrary

fileprivate let hStackSpacing: CGFloat = 12.0
fileprivate let labelWidth: CGFloat = 140
fileprivate let pickerWidth: CGFloat = 200
fileprivate let rowHeight: CGFloat = 35
#if os(macOS)
fileprivate let interFieldSpacing: CGFloat = 0
#else
fileprivate let interFieldSpacing: CGFloat = 3
#endif
// MARK: --- Focus identifiers for amount fields
enum AmountFieldIdentifier: Hashable {
    case mainAmountField
    case splitAmountField
}

// MARK: --- Main View
struct AddOrEditTransactionView: View {
    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    
    // MARK: --- State
    @State private var transactionData: TransactionStruct
    @State private var splitTransaction: Bool
    @FocusState private var focusedField: AmountFieldIdentifier?
    // Counter Transaction
    @State private var counterTransactionActive: Bool = false
    @State private var counterPaymentMethod: ReconcilableAccounts? = nil
    @State private var counterFXRate: Decimal = 0
    
    // MARK: --- External
    var existingTransaction: Transaction?
    var onSave: ((TransactionStruct) -> Void)?
    
    // MARK: --- Initialisers
    init(transaction: Transaction? = nil, onSave: ((TransactionStruct) -> Void)? = nil) {
        if let transaction {
            let structData = TransactionStruct(from: transaction)
            _transactionData = State(initialValue: structData)
            _splitTransaction = State(initialValue: structData.isSplit)
        } else {
            _transactionData = State(initialValue: TransactionStruct())
            _splitTransaction = State(initialValue: false)
        }
        self.existingTransaction = transaction
        self.onSave = onSave
    }
    
    init(transactionID: NSManagedObjectID?, context: NSManagedObjectContext, onSave: ((TransactionStruct) -> Void)? = nil) {
        if let transactionID,
           let transaction = try? context.existingObject(with: transactionID) as? Transaction {
            let structData = TransactionStruct(from: transaction)
            _transactionData = State(initialValue: structData)
            _splitTransaction = State(initialValue: structData.isSplit)
            self.existingTransaction = transaction
        } else {
            _transactionData = State(initialValue: TransactionStruct())
            _splitTransaction = State(initialValue: false)
            self.existingTransaction = nil
        }
        self.onSave = onSave
    }
    
    // MARK: --- CanSave
    private var canSave: Bool {
        guard let txDate = transactionData.transactionDate else { return false }
        return txDate <= Date() &&
        transactionData.txAmount != 0 &&
        (transactionData.payee?.isEmpty == false) &&
        transactionData.category != .unknown &&
        (transactionData.currency == .GBP ||
         (transactionData.exchangeRate != 0 && (transactionData.currency == .JPY ? transactionData.exchangeRate < 300 : true)))
    }
    
    // MARK: --- Body
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
//                header
                mainFields
                splitSection
                actionButtons
            }
            .frame(maxWidth: 700)
            .font(.system(size: 11))
            .padding()
            .onTapGesture { focusedField = nil }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: --- Header
//    private var header: some View {
//        Text(existingTransaction == nil ? "Add Transaction" : "Edit Transaction")
//            .font(.title2)
//            .fontWeight(.semibold)
//            .padding(.top, 16)
//            .padding(.horizontal, 14)
//    }
    
    // MARK: --- Main Fields
    private var mainFields: some View {
        GroupBox(label: Label("Transaction Details", systemImage: "doc.text")) {
            VStack(spacing: interFieldSpacing ) {
                
                LabeledDatePicker(
                    label: "TX Date",
                    date: Binding(
                        get: { transactionData.transactionDate ?? Date() },
                        set: { transactionData.transactionDate = $0 }
                    ),
                    displayedComponents: [.date],
                    isValid: transactionData.isTransactionDateValid()
                )
                
                LabeledPicker(label: "Payer", selection: $transactionData.payer, isValid: transactionData.isPayerValid())
                
                LabeledPicker(label: "Currency", selection: $transactionData.currency, isValid: transactionData.isCurrencyValid())
                
                if transactionData.currency != .GBP {
                    LabeledDecimalField(label: "Exchange Rate", amount: $transactionData.exchangeRate, isValid: transactionData.isExchangeRateValid())
                }
                
                LabeledPicker(label: "Debit/Credit", selection: $transactionData.debitCredit, isValid: transactionData.debitCredit != .unknown)
                
                LabeledDecimalWithFX(label: "Amount", amount: $transactionData.txAmount, currency: $transactionData.currency, fxRate: $transactionData.exchangeRate, isValid: transactionData.isTXAmountValid(), displayOnly: false)
                    .focused($focusedField, equals: .mainAmountField)
                
                LabeledPicker(label: "Payment Method", selection: $transactionData.paymentMethod, isValid: transactionData.isPaymentMethodValid())
                
                LabeledTextField(label: "Payee", text: Binding(get: { transactionData.payee ?? "" }, set: { transactionData.payee = $0 }), isValid: transactionData.isPayeeValid())
                    .onChange(of: transactionData.payee) { _, newValue in
                        guard let payee = newValue, !payee.isEmpty else { return }
                        let matcher = CategoryMatcher(context: viewContext)
                        transactionData.category = matcher.matchCategory(for: payee)
                    }
                
                HStack(spacing: 8) {
                    LabeledPicker(
                        label: "Category",
                        selection: $transactionData.category,
                        isValid: transactionData.isCategoryValid()
                    )
                    
                    Button("Suggest") {
                        if let payee = transactionData.payee, !payee.isEmpty {
                            let matcher = CategoryMatcher(context: viewContext)
                            transactionData.category = matcher.matchCategory(for: payee)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.system(size: 11))
                }
                
                LabeledTextField(label: "Explanation", text: Binding(get: { transactionData.explanation ?? "" }, set: { transactionData.explanation = $0 }), isValid: true)
            }
        }
    }
    
    // MARK: --- Split Section
    private var splitSection: some View {
    #if os(iOS)
        VStack(spacing: 16) {
            SplitTransactionView(
                transactionData: $transactionData,
                splitTransaction: $splitTransaction,
//                focusedField: $focusedField
            )
            CounterTransactionView(
                transactionData: $transactionData,
                counterTransaction: $counterTransactionActive,
                counterPaymentMethod: $counterPaymentMethod,
                counterFXRate:        $counterFXRate

            )
        }
    #elseif os(macOS)
        HStack(alignment: .top, spacing: 16) {
            SplitTransactionView(
                transactionData:     $transactionData,
                splitTransaction:    $splitTransaction,
            )
            .frame(minWidth: 300)
            .focused($focusedField, equals: .splitAmountField)

            CounterTransactionView(
                transactionData:      $transactionData,
                counterTransaction:   $counterTransactionActive,
                counterPaymentMethod: $counterPaymentMethod,
                counterFXRate:        $counterFXRate
            )
            .frame(minWidth: 300)
        }
    #endif
    }

    // MARK: --- SplitTransactionView
    struct SplitTransactionView: View {
        @Binding var transactionData: TransactionStruct
        @Binding var splitTransaction: Bool
        @FocusState var focusedField: AmountFieldIdentifier? // <-- pass parent state as Binding

        var body: some View {
            GroupBox(label: Label("Split Transaction", systemImage: "square.split.2x1")) {
                VStack(spacing: 8 ) {
                    Button(splitTransaction ? "Unsplit Transaction" : "Split Transaction") {
                        if splitTransaction {
                            splitTransaction = false
                            transactionData.splitAmount = 0
                            transactionData.splitCategory = .unknown
                        } else {
                            splitTransaction = true
                            let half = (transactionData.txAmount / 2).rounded(scale: 2, roundingMode: .up)
                            transactionData.splitAmount = half
                            transactionData.splitCategory = .unknown
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    VStack(spacing: interFieldSpacing ) {
                        LabeledDecimalWithFX(
                            label: "Split",
                            amount: $transactionData.splitAmount,
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: !splitTransaction || transactionData.isSplitAmountValid()
                        )
                        .focused($focusedField, equals: .splitAmountField)

                        LabeledPicker(
                            label: "Split Category",
                            selection: $transactionData.splitCategory,
                            isValid: !splitTransaction || transactionData.isSplitCategoryValid()
                        )

                        LabeledDecimalWithFX(
                            label: "Remainder",
                            amount: Binding(get: { transactionData.splitRemainderAmount }, set: { _ in }),
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: true,
                            displayOnly: true
                        )

                        LabeledPicker(
                            label: "Remainder Category",
                            selection: $transactionData.category,
                            isValid: !splitTransaction || transactionData.isSplitRemainderCategoryValid()
                        )
                    }
                    .disabled(!splitTransaction)
                    .opacity(splitTransaction ? 1.0 : 0.5)
                }
            }
        }
    }
    
    //    // MARK: --- CounterTransactionView
    struct CounterTransactionView: View {
        @Binding var transactionData: TransactionStruct
        @Binding var counterTransaction: Bool
        @Binding var counterPaymentMethod: ReconcilableAccounts?
        @Binding var counterFXRate: Decimal
        
        // Suggested counter methods based on PaymentMethod + Category
        private var suggestedCounterMethods: [ReconcilableAccounts] {
            if let suggested = CounterTriggers.trigger(
                for: transactionData.paymentMethod,
                category: transactionData.category
            ) {
                return [suggested]
            }
            return []
        }
        
        var body: some View {
            GroupBox(label: Label("Counter Transaction", systemImage: "arrow.2.squarepath")) {
                VStack(spacing: 12) {
                    
                    Button(counterTransaction ? "Remove Counter Transaction" : "Add Counter Transaction") {
                        counterTransaction.toggle()
                        
                        if counterTransaction {
                            // Auto-suggest top picker if a trigger exists
                            counterPaymentMethod = suggestedCounterMethods.first ?? .unknown
                        } else {
                            counterPaymentMethod = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    VStack(spacing: 8) {
                        
                        // --- FX If counter transaction is different currency ---
                        if counterTransaction && transactionData.paymentMethod.currency != counterPaymentMethod?.currency {
                            LabeledDecimalField(
                                label: "Counter FX Rate",
                                amount: $counterFXRate,
                                isValid: counterFXRate > 0
                            )
                        }
                        
                        // --- Top Picker: Suggested Counter Methods ---
                        if !suggestedCounterMethods.isEmpty {
                            LabeledPicker(
                                label: "Suggested Counter Pmt",
                                selection: Binding(
                                    get: { counterPaymentMethod ?? .unknown },
                                    set: { counterPaymentMethod = $0 }
                                ),
                                isValid: counterPaymentMethod != nil && counterPaymentMethod != .unknown,
                                items: suggestedCounterMethods
                            )
                        }
                        
                        // --- Bottom Picker: Manual Payment Method (any) ---
                        LabeledPicker(
                            label: "Chosen Counter Pmt",
                            selection: Binding(
                                get: { counterPaymentMethod ?? .unknown },
                                set: { counterPaymentMethod = $0 }
                            ),
                            isValid: counterPaymentMethod != nil && counterPaymentMethod != .unknown
                        )
                        
                        // --- Amount Box ---
                        LabeledDecimalWithFX(
                            label: "Counter Pmt Amount",
                            amount: Binding(
                                get: {
                                    guard let method = counterPaymentMethod else { return transactionData.txAmount }
                                    if transactionData.currency == method.currency {
                                        return transactionData.txAmount
                                    } else {
                                        guard counterFXRate > 0 else { return 0 }
                                        // Convert via GBP
                                        let gbpValue = transactionData.currency == .GBP
                                            ? transactionData.txAmount
                                            : transactionData.txAmount / transactionData.exchangeRate
                                        return gbpValue * counterFXRate
                                    }
                                },
                                set: { _ in }
                            ),
//                            amount: Binding(get: { transactionData.txAmount }, set: { _ in }),
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: true,
                            displayOnly: true
                        )
                        
                    }
                    .disabled(!counterTransaction)
                    .opacity(counterTransaction ? 1.0 : 0.5)
                    .if(gViewCheck) { view in view.border(.green) }
                }
                .padding(.vertical, 8)
                .if(gViewCheck) { view in view.border(.orange) }
            }
            .if(gViewCheck) { view in view.border(.red) }
        }
    }
    
    // MARK: --- Action Buttons
    private var actionButtons: some View {
        GroupBox(label: Label("Transaction Disposition", systemImage: "square.and.arrow.down")) {
            HStack {
                Spacer()
                Button("Don't Save", role: .cancel) {
                    appState.popCentralView()
                    resetForm()
#if os(iOS)
                    dismiss()
#endif
                }
                .padding()
                
                Button("Save") {
                    saveTransaction()
                    appState.popCentralView()
                    resetForm()
#if os(iOS)
                    dismiss()
#endif
                }
                .disabled(!transactionData.isValid())
                .buttonStyle(.borderedProminent)
                .padding()
                Spacer()
            }
        }
    }
    
    // MARK: --- HELPERS
    
    // MARK: --- ResetForm
    private func resetForm() {
        transactionData = TransactionStruct()
        transactionData.setDefaults()
    }
    
    // MARK: --- SaveTransaction
    private func saveTransaction() {
        // --- Save main transaction
        let tx = existingTransaction ?? Transaction(context: viewContext)
        transactionData.apply(to: tx)
        
        // --- Save counter transaction if active
        if counterTransactionActive, let method = counterPaymentMethod, method != .unknown {
            let counterTx = Transaction(context: viewContext)
            var counterData = transactionData
            
            // Set counter payment method
            counterData.paymentMethod = method
            
            // Set counter currency
            counterData.currency = method.currency
            
            // Prompted FX rate for non-GBP counter
            if counterData.currency == .GBP {
                counterData.exchangeRate = 1
            } else {
                // exchangeRate should have been prompted from the user in the UI
                // Make sure it is set
                counterData.exchangeRate = counterFXRate
            }
            
            // Convert main transaction amount to GBP
            let amountInGBP: Decimal
            if transactionData.currency == .GBP {
                amountInGBP = transactionData.txAmount
            } else {
                amountInGBP = transactionData.txAmount / transactionData.exchangeRate
            }
            
            // Set counter transaction amount in counter currency
            counterData.txAmount = -amountInGBP * counterData.exchangeRate
            
            // Apply to counter transaction
            counterData.apply(to: counterTx)
        }
        
        // --- Save context
        do {
            try viewContext.save()
        } catch {
            print("Failed to save transaction: \(error)")
            viewContext.rollback()
        }
        
        // --- Teach category mapping for main transaction
        if let payee = transactionData.payee {
            let matcher = CategoryMatcher(context: viewContext)
            matcher.teachMapping(for: payee, category: transactionData.category)
        }
    }


//    private func saveTransaction() {
//        // Save main transaction
//        let tx = existingTransaction ?? Transaction(context: viewContext)
//        transactionData.apply(to: tx)
//        
//        // Save counter transaction if active
//        if counterTransactionActive,
//           counterPaymentMethod != .unknown {
//            let counterTx = Transaction(context: viewContext)
//            var counterData = transactionData
//            counterData.txAmount = -transactionData.txAmount
//            if let method = counterPaymentMethod {
//                counterData.paymentMethod = method
//            }
//            counterData.apply(to: counterTx)
//        }
//        
//        do {
//            try viewContext.save()
//        } catch {
//            print("Failed to save transaction: \(error)")
//            viewContext.rollback()
//        }
//        
//        // Teach category mapping for main transaction
//        if let payee = transactionData.payee {
//            let matcher = CategoryMatcher(context: viewContext)
//            matcher.teachMapping(for: payee, category: transactionData.category)
//        }
//    }
}


// MARK: --- LabeledDatePicker
#if os(iOS)
struct LabeledDatePicker: View {
    let label: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    let isValid: Bool   // added back

    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
                .foregroundColor(.secondary)
            Spacer()
            DatePicker(
                "",
                selection: $date,
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .padding(.horizontal)
        .frame(height: rowHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
        .contentShape(Rectangle()) // full row tappable
        .onTapGesture {
            focused = true
        }
        .font(.body)
    }
}
#elseif os(macOS)
struct LabeledDatePicker: View {
    let label: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    let isValid: Bool   // added back

    private let hStackSpacing: CGFloat = 8
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            DatePicker(
                "",
                selection: $date,
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.field)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isValid ? Color.clear : Color.red)
            )
            Spacer()
        }
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}
#endif

// MARK: --- LabeledPicker<T>
#if os(iOS)
struct LabeledPicker<T: CaseIterable & Hashable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    let isValid: Bool
    var items: [T]? = nil   // Optional filtered items
    
    @State private var showDialog = false

    var body: some View {
//        let displayItems = items ?? Array(T.allCases)
        // --- Ensure current selection is always in the list
        let displayItems: [T] = {
            if let items = items {
                if items.contains(selection) {
                    return items
                } else {
                    return items + [selection]
                }
            } else {
                return Array(T.allCases)
            }
        }()
        
        HStack {
            Text(label)
                .padding(.leading, 14)
                .frame(width: labelWidth, alignment: .leading)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Text(selection.description)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .frame(height: rowHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .font(.body)
        .onTapGesture {
            showDialog = true
        }
        .confirmationDialog("Select \(label)", isPresented: $showDialog, titleVisibility: .visible) {
            ForEach(displayItems, id: \.self) { option in
                Button(option.description) {
                    selection = option
                }
            }
        }
    }
}
#elseif os(macOS)
struct LabeledPicker<T: CaseIterable & Hashable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    let isValid: Bool
    var items: [T]? = nil   // Optional filtered items

    private let hStackSpacing: CGFloat = 8
    @FocusState private var focused: Bool

    var body: some View {
//        let displayItems = items ?? Array(T.allCases)
        // --- Ensure current selection is always in the list
        let displayItems: [T] = {
            if let items = items {
                if items.contains(selection) {
                    return items
                } else {
                    return items + [selection]
                }
            } else {
                return Array(T.allCases)
            }
        }()
        
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            
            Picker("", selection: $selection) {
                ForEach(displayItems, id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: pickerWidth, alignment: .leading)
//            .padding(0)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isValid ? Color.clear : Color.red)
            )
            Spacer( )
        }
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}
#endif

// MARK: --- LabeledDecimalField
#if os(iOS)
struct LabeledDecimalField: View {
    let label: String
    @Binding var amount: Decimal
    let isValid: Bool
    @FocusState private var focused: Bool
    @State private var text: String = ""

    private func commit() {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        if let number = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) {
            amount = number
        }
        text = formatDecimal(amount)
    }

    var body: some View {
        HStack {
            Text(label)
                .frame(width: labelWidth, alignment: .leading) // left-align to match other fields
                .padding(.leading, 14) // aligns with other controls
                .foregroundColor(.secondary)
            Spacer()
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 80)
                .padding(.trailing, 8)
                .keyboardType(.numbersAndPunctuation)
                .focused($focused)
                .submitLabel(.done)
                .onAppear { text = formatDecimal(amount) }
                .onChange(of: focused) { _, new in if !new { commit() } }
                .onSubmit { commit() }
                .toolbar {
                    if focused {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                focused = false
                                commit()
                            }
                        }
                    }
                    
                }
        }
        .frame(height: rowHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .font(.body)
        .onTapGesture {
            focused = true
        }

    }
}
#elseif os(macOS)
struct LabeledDecimalField: View {
    let label: String
    @Binding var amount: Decimal
    let isValid: Bool
    @FocusState private var focused: Bool
    @State private var text: String = ""
    
    private func commit() {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        if let number = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) {
            amount = number
        }
        text = formatDecimal(amount)
    }
    
    var body: some View {
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 80)
                .focused($focused)
                .onAppear { text = formatDecimal(amount) }
                .onChange(of: focused) { _, new in if !new { commit() } }
                .onSubmit { commit() }
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(isValid ? Color.clear : Color.red))
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
//#if os(iOS)
            focused = true
//#endif
        }
    }
}
#endif

// MARK: --- LabeledDecimalWithFX
#if os(iOS)
struct LabeledDecimalWithFX: View {
    
    let label: String
    @Binding var amount: Decimal
    @Binding var currency: Currency
    @Binding var fxRate: Decimal
    let isValid: Bool
    var displayOnly: Bool = false  // display-only mode
    
    @FocusState var focusedField: AmountFieldIdentifier?
    var fieldID: AmountFieldIdentifier = .mainAmountField
    
    @State private var text: String = ""
    
    private var amountInGBP: Decimal? {
        guard currency != .GBP && fxRate != Decimal(0) else { return nil }
        return amount / fxRate
    }
    
    private func commitText() {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        if let number = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) {
            amount = number
        }
        text = formatDecimal(amount)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 14)
                .foregroundColor(.secondary)
            
            if displayOnly {
                Text(formatDecimal(amount))
                    .frame(width: 80, alignment: .leading)
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .background(Color(UIColor.systemBackground)) // system adaptive background
                    .keyboardType(.numbersAndPunctuation)
                    .focused($focusedField, equals: fieldID)
                    .onSubmit {
                        focusedField = nil
                        commitText()
                    }
                    .onChange(of: focusedField) { _, newFocused in
                        if newFocused != fieldID {
                            commitText()
                        }
                    }
                    .onAppear { text = formatDecimal(amount) }
                    .onChange(of: amount) { _, newAmount in
                        let formatted = formatDecimal(newAmount)
                        if formatted != text {
                            text = formatted
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .toolbar {
                        if focusedField != nil {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    focusedField = nil // dismiss whichever field is active
                                    commitText()       // commit main amount
                                    // commit FX if needed
                                }
                            }
                        }
                    }
            }
            
            // FX display
            if let gbp = amountInGBP {
                Text("GBP: \(formatDecimal(gbp))")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(height: rowHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
        .contentShape(Rectangle()) // entire row tappable
        .font(.body)
        .onTapGesture {
            if !displayOnly {
                focusedField = fieldID
            }
        }

    }
}
#elseif os(macOS)
struct LabeledDecimalWithFX: View {
    let label: String
    @Binding var amount: Decimal
    @Binding var currency: Currency
    @Binding var fxRate: Decimal
    let isValid: Bool
    var displayOnly: Bool = false  // display-only mode
    
    @FocusState var focusedField: AmountFieldIdentifier?
    var fieldID: AmountFieldIdentifier = .mainAmountField
    
    @State private var text: String = ""
    
    private var amountInGBP: Decimal? {
        guard currency != .GBP && fxRate != Decimal(0) else { return nil }
        return amount / fxRate
    }
    
    private func commitText() {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        if let number = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) {
            amount = number
        }
        text = formatDecimal(amount)
    }
    
    var body: some View {
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            
            if displayOnly {
                Text(formatDecimal(amount))
                    .frame(maxWidth: 80, alignment: .leading)
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 80)
                    .focused($focusedField, equals: fieldID)
                    .onSubmit {
                        focusedField = nil
                        commitText()
                    }
                    .onChange(of: focusedField) { _, newFocused in
                        if newFocused != fieldID {
                            commitText()
                        }
                    }
                    .onAppear {
                        text = formatDecimal(amount)
                    }
                    .onChange(of: amount) { _, newAmount in
                        let formatted = formatDecimal(newAmount)
                        if formatted != text {
                            text = formatted
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                    )
            }
            
            // FX display
            if let gbp = amountInGBP {
                Text("GBP: \(formatDecimal(gbp))")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle()) // entire row tappable
        .onTapGesture {
        }
    }
}
#endif


// MARK: --- LabeledTextField
#if os(iOS)
struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    let isValid: Bool
    
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
                .foregroundColor(.secondary)
            Spacer()
            TextField("", text: $text)
                .focused($focused)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal)
        .frame(height: rowHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
        .contentShape(Rectangle()) // full row tappable
        .onTapGesture {
            focused = true
        }
        .font(.body)
    }
}
#elseif os(macOS)
struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    let isValid: Bool
    @FocusState private var focused: Bool
    
    private let hStackSpacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isValid ? Color.clear : Color.red)
                )
            Spacer()
        }
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}
#endif


// MARK: --- Helper
fileprivate func formatDecimal(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: value as NSDecimalNumber) ?? "0.00"
}
