//
//  ImportError.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/01/2026.
//

import Foundation

import Foundation

enum ImportError: LocalizedError {
    case missingAccountNumberColumn
    case unknownAccount(String)
    case inconsistentAccountNumber
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .missingAccountNumberColumn:
            return "The CSV file does not contain an Account Number column."

        case .unknownAccount(let accountNumber):
            return "The account number \(accountNumber) is not recognised."

        case .inconsistentAccountNumber:
            return "The CSV file contains multiple account numbers. Each file must be for a single account."

        case .emptyFile:
            return "The CSV file is empty or contains no transaction rows."
        }
    }
}
