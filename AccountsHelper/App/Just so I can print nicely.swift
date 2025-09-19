//
//  Just so I can print nicely.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/09/2025.
//

import Foundation

import SwiftUI

// Does not seem to be used
struct AmountFieldXXX: View {
    @State private var text: String = ""
    @State private var error: String? = nil

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Enter amount", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) { newValue in
                    validate(newValue)
                }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    func validate(_ value: String) {
        // Example: must be a number greater than 0
        if let number = Decimal(string: value), number > 0 {
            error = nil
        } else {
            error = "Please enter a valid positive number"
        }
    }
}
