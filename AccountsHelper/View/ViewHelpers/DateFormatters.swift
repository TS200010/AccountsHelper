//
//  DateFormatters.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

// MARK: - DateFormatter

import SwiftUI

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .medium
    return f
}()

//let dateOnlyFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .medium
//    formatter.timeStyle = .none  // <-- no time
//    return formatter
//}()

let dateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy" // or "dd/MM/yyyy" etc
    return formatter
}()

