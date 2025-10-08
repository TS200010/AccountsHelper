//
//  DateFormatters.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import SwiftUI

// MARK: --- DateFormatter with date & time
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

// MARK: --- DateFormatter with date only
let dateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy" // or "dd/MM/yyyy" etc
    return formatter
}()
