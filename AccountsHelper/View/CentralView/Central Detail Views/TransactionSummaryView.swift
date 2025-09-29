//
//  TransactionSummaryView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 28/09/2025.
//

import SwiftUI


import SwiftUI

struct TransactionSummaryView: View {
    let transactions: [Transaction]
    let paymentMethod: PaymentMethod

    // Pre-format into [String: String]
    private var totals: [String: String] {
        var dict: [String: String] = [:]
        let byCategory = transactions.sumByCategoryIncludingSplits(for: paymentMethod)

        for (category, value) in byCategory {
            let doubleValue = NSDecimalNumber(decimal: value).doubleValue
            let formatted = String(format: "%.2f", doubleValue)
            dict[category.description] = formatted
        }

        return dict
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(totals.keys), id: \.self) { category in
                    HStack {
                        Text(category)
                            .font(.body)
                        Spacer()
                        Text(totals[category] ?? "0.00")
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Transaction Summary")
    }
}




