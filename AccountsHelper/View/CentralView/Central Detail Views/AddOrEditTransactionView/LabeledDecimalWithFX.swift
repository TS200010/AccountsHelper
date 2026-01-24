//
//  LabeledDecimalWithFX.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {
   
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
            HStack(spacing: gHStackSpacing) {
                Text(label)
                    .frame(width: gLabelWidth, alignment: .trailing)
                
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
}
