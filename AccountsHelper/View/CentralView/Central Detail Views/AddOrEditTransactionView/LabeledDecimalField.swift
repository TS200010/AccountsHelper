//
//  LabeledDecimalField.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {

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
            HStack(spacing: gHStackSpacing) {
                Text(label)
                    .frame(width: gLabelWidth, alignment: .trailing)
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


    
}

