//
//  EditTransactionView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import SwiftUI
import CoreData

fileprivate let hStackSpacing: CGFloat = 12.0
fileprivate let labelWidth: CGFloat = 120
fileprivate let rowHeight: CGFloat = 44

// Focus identifiers for amount fields
enum AmountFieldIdentifier: Hashable {
    case main
    case split1
}

// MARK: --- EditTransactionView
struct EditTransactionView: View {
    
//    @State var transaction: Transaction?
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) var appState
    
    @FocusState private var focusedField: AmountFieldIdentifier?

//    private var existingTransaction: Transaction?
    // TODO: --- Consider removing the optional
    @State private var existingTransaction: Transaction?
    
    // MARK: --- State Variables
    @State private var category: Category = .unknown
    @State private var splitCategory: Category = .unknown
    @State private var currency: Currency = .GBP
    @State private var debitCredit: DebitCredit = .DR
    @State private var exchangeRate: Decimal = 1.00
    @State private var explanation: String = ""
    @State private var payee: String = ""
    @State private var payer: Payer = .tony
    @State private var paymentMethod: PaymentMethod = .AMEX
    @State private var txAmount: Decimal = Decimal(0)
    @State private var splitAmount: Decimal = Decimal(0)
    @State private var splitTransaction: Bool = false
    @State private var transactionDate: Date = Date()
    @State private var timeStamp: Date = Date()
    @State private var hasLoaded: Bool = false
    
//    init(){
//        resetForm()
//    }
    
    init(transaction: Transaction? = nil) {
        self.existingTransaction = transaction
        _category        = State(initialValue: transaction?.category ?? .unknown)
        _splitCategory   = State(initialValue: transaction?.splitCategory ?? .unknown)
        _currency        = State(initialValue: transaction?.currency ?? .GBP)
        _debitCredit     = State(initialValue: transaction?.debitCredit ?? .DR)
        _exchangeRate    = State(initialValue: transaction?.exchangeRate ?? Decimal(1))
        _explanation     = State(initialValue: transaction?.explanation ?? "")
        _payee           = State(initialValue: transaction?.payee ?? "")
        _payer           = State(initialValue: transaction?.payer ?? .tony)
        _paymentMethod   = State(initialValue: transaction?.paymentMethod ?? .AMEX)
        _txAmount        = State(initialValue: transaction?.txAmount ?? Decimal(0))
        _splitAmount     = State(initialValue: transaction?.splitAmount ?? Decimal(0))
        _transactionDate = State(initialValue: transaction?.transactionDate ?? Date.distantPast)
        _splitTransaction = State(initialValue: transaction?.splitAmount != Decimal(0)) // optional
        _timeStamp       = State(initialValue: transaction?.timestamp ?? Date.distantPast)
    }
    
    // MARK: --- Validation
    private var canSave: Bool {
        isTransactionDateValid() &&
        isTXAmountValid() &&
        isExchangeRateValid() &&
        isPayeeValid() &&
        isCategoryValid()
    }
    
    func isTXAmountValid() -> Bool { txAmount != Decimal(0) }
    func isCategoryValid() -> Bool { category != .unknown }
    func isExchangeRateValid() -> Bool { currency == .GBP || (exchangeRate != Decimal(0) && (currency == .JPY ? exchangeRate < 300 : true)) }
    func isDebitCreditValid() -> Bool { debitCredit != .unknown }
    func isPayeeValid() -> Bool { !payee.isEmpty }
    func isSplitAmountValid() -> Bool { splitAmount != 0 && splitAmount < txAmount }
    func isTransactionDateValid() -> Bool { transactionDate <= Date() }
    
    // MARK: --- Reset
    func resetForm() {
        category = .unknown
        splitCategory = .unknown
        currency = .GBP
        debitCredit = .DR
        exchangeRate = Decimal(0)
        explanation = ""
        payee = ""
        payer = .tony
        paymentMethod = .AMEX
        txAmount = Decimal(0)
        splitAmount = Decimal(0)
        splitTransaction = false
        transactionDate = Date()
        timeStamp = Date()
    }
    
    // MARK: --- Save
    func saveTransaction() {
        let transaction = existingTransaction ?? Transaction(context: viewContext)

        transaction.category = category
        transaction.splitCategory = splitCategory
        transaction.currency = currency
        transaction.debitCredit = debitCredit
        transaction.exchangeRate = exchangeRate
        transaction.explanation = explanation
        transaction.payee = payee
        transaction.payer = payer
        transaction.paymentMethod = paymentMethod
        transaction.txAmount = txAmount
        transaction.splitAmount = splitAmount
        transaction.transactionDate = transactionDate
        transaction.timestamp = timeStamp
        
        do {
            try viewContext.save()
            print("Transaction saved!")
        } catch {
            print("Failed to save transaction: \(error)")
            assert(false)
        }
        
        // Update the CategoryMatcher
        let matcher = CategoryMatcher(context: viewContext)
        matcher.teachMapping(for: payee, category: category)
        
    }
    
    // MARK: --- Body
    var body: some View {
        ScrollView{
            VStack(spacing: 10) {
                
#if os(iOS)
                Text("Add Transaction")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
#endif
                
                LabeledDatePicker(label: "TX Date", date: $transactionDate, displayedComponents: [ .date ], isValid: isTransactionDateValid())
                
                LabeledPicker(label: "Payer", selection: $payer, isValid: true)
                
                LabeledPicker(label: "Currency", selection: $currency, isValid: true)
                
                if currency != .GBP {
                    LabeledDecimalField(label: "Exchange Rate", amount: $exchangeRate, isValid: isExchangeRateValid())
                }
                
                LabeledPicker(label: "Debit/Credit", selection: $debitCredit, isValid: isDebitCreditValid() )
                
                LabeledDecimalWithFX(label: "Amount", amount: $TXAmount, currency: $currency, fxRate: $exchangeRate, isValid: isTXAmountValid())
                    .focused($focusedField, equals: AmountFieldIdentifier.main)
                
                LabeledPicker(label: "Payment Method", selection: $paymentMethod, isValid: true)
                
//                LabeledTextField(label: "Payee", text: $payee, isValid: isPayeeValid())
                LabeledTextField(label: "Payee", text: $payee, isValid: isPayeeValid())
                    .onChange(of: payee) { newValue in
                        guard !newValue.isEmpty else { return }
                        let matcher = CategoryMatcher(context: viewContext)
                        category = matcher.matchCategory(for: newValue)
                    }

                
                LabeledPicker(label: "Category", selection: $category, isValid: isCategoryValid())
                
                LabeledTextField(label: "Explanation", text: $explanation, isValid: true)
                
                // MARK: --- Split Transaction
                if !splitTransaction {
                    Button("Split Transaction") {
                        splitTransaction = true
                        let half = (TXAmount / 2).rounded(scale: 2, roundingMode: .up)
                        splitAmount = half
                        splitCategory = .unknown
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Unsplit Transaction") {
                        splitTransaction.toggle()
                        splitAmount = Decimal(0)
                        splitCategory = .unknown
                    }
                    .buttonStyle(.borderedProminent)
                    
                    VStack(spacing: 0) {
                        // --- Split 1 (editable)
                        LabeledDecimalWithFX(
                            label: "Split 1",
                            amount: $splitAmount,
                            currency: $currency,
                            fxRate: $exchangeRate,
                            isValid: isSplitAmountValid()
                        )
                        .focused($focusedField, equals: .split1)
                        
                        LabeledPicker(label: "Split 1 Category", selection: $splitCategory, isValid: true)
                        
                        // --- Split 2 (display-only, always TXAmount - splitAmount)
                        LabeledDecimalWithFX(
                            label: "Split 2",
                            amount: Binding(
                                get: { TXAmount - splitAmount },
                                set: { _ in } // read-only
                            ),
                            currency: $currency,
                            fxRate: $exchangeRate,
                            isValid: true,
                            displayOnly: true
                        )
                        
                        LabeledPicker(label: "Split 2 Category", selection: $category, isValid: true)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Don't Save", role: .cancel) {
                        appState.selectedTransactionID = nil   // Clear selection
                        appState.popCentralView( )
//                        appState.selectedCentralView = .emptyView
//                        dismiss()
                    }
                    .padding()
                    
                    Button("Save") {
                        saveTransaction()
                        appState.selectedTransactionID = nil   // Clear selection
                        if existingTransaction == nil {
                            resetForm() // only reset when adding a new one
                        }
                        appState.popCentralView( )
//                        appState.selectedCentralView = .emptyView
//                        dismiss()
                    }
                    .disabled(!canSave)
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Spacer()
                }
            }
            .frame(maxWidth: 700)
            .font(.system(size: 11))
            .padding()
            .onTapGesture {
                focusedField = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // fills parent
//        .background(Color(Color.platformTextBackgroundColor))
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            
            if let selectedID = appState.selectedTransactionID {
                // Existing transaction: fetch and populate
                if let tx = try? viewContext.existingObject(with: selectedID) as? Transaction {
                    existingTransaction = tx
                    category = tx.category
                    splitCategory = tx.splitCategory
                    currency = tx.currency
                    debitCredit = tx.debitCredit
                    exchangeRate = tx.exchangeRate
                    explanation = tx.explanation ?? ""
                    payee = tx.payee ?? ""
                    payer = tx.payer
                    paymentMethod = tx.paymentMethod
                    TXAmount = tx.txAmount
                    splitAmount = tx.splitAmount
                    transactionDate = tx.transactionDate ?? Date.distantPast
                    splitTransaction = tx.splitAmount != Decimal(0)
                    timeStamp = tx.timestamp ?? Date.distantPast
                }
            } else {
                // New transaction: keep defaults (already set in @State)
                resetForm()
            }
        }
        .onDisappear {
            appState.selectedTransactionID = nil
        }
    }
}

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

// MARK: --- Generic Picker Field
#if os(iOS)
struct LabeledPicker<T: CaseIterable & Hashable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    let isValid: Bool
    
    @State private var showDialog = false

    var body: some View {
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
        .background(Color(UIColor.secondarySystemBackground)) // single grey
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
            ForEach(Array(T.allCases), id: \.self) { option in
                Button(option.description) {
                    selection = option
                }
            }
        }
    }
}
#elseif os(macOS)
struct LabeledPicker<T: CaseIterable & Hashable>: View where T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    let isValid: Bool

    private let hStackSpacing: CGFloat = 8
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: hStackSpacing) {
            Text(label)
                .frame(width: labelWidth, alignment: .trailing)
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 150)
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

// MARK: --- Generic Number Field
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
                .keyboardType(.decimalPad)
                .focused($focused)
                .submitLabel(.done)
                .onAppear { text = formatDecimal(amount) }
                .onChange(of: focused) { new in if !new { commit() } }
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
                .onChange(of: focused) { new in if !new { commit() } }
                .onSubmit { commit() }
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(isValid ? Color.clear : Color.red))
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
#if os(iOS)
            focused = true
#endif
        }
    }
}
#endif

// MARK: --- Generic Number Field with FX
#if os(iOS)
struct LabeledDecimalWithFX: View {
    
    let label: String
    @Binding var amount: Decimal
    @Binding var currency: Currency
    @Binding var fxRate: Decimal
    let isValid: Bool
    var displayOnly: Bool = false  // display-only mode
    
    @FocusState var focusedField: AmountFieldIdentifier?
    var fieldID: AmountFieldIdentifier = .main
    
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
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: fieldID)
                    .onSubmit {
                        focusedField = nil
                        commitText()
                    }
                    .onChange(of: focusedField) { newFocused in
                        if newFocused != fieldID {
                            commitText()
                        }
                    }
                    .onAppear { text = formatDecimal(amount) }
                    .onChange(of: amount) { newAmount in
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
    var fieldID: AmountFieldIdentifier = .main
    
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
                    .onChange(of: focusedField) { newFocused in
                        if newFocused != fieldID {
                            commitText()
                        }
                    }
                    .onAppear {
                        text = formatDecimal(amount)
                    }
                    .onChange(of: amount) { newAmount in
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


// MARK: --- Generic Text Field
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
