//
//  LabeledPicker.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI
extension AddOrEditTransactionView {
    
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
                    .frame(width: gLabelWidth, alignment: .trailing)
                
                Picker("", selection: $selection) {
                    ForEach(displayItems, id: \.self) { option in
                        Text(option.description).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: gPickerWidth, alignment: .leading)
    //            .padding(0)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isValid ? Color.clear : Color.red)
                )
                Spacer( )
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
