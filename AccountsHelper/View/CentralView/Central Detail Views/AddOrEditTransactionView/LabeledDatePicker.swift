//
//  LabeledDatePicker.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {
    
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
                    .frame(width: gLabelWidth, alignment: .trailing)
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
            .frame(height: gRowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                focused = true
            }
        }
    }
    #endif

}

