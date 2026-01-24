//
//  LabeledTextField.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {
   
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
                    .frame(width: gLabelWidth, alignment: .trailing)
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isValid ? Color.clear : Color.red)
                    )
                Spacer()
            }
            .frame(height: gRowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                focused = true
            }
        }
    }
    #endif
}

