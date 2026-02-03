//
//  ReconcilableAccounts.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/09/2024.
//

import Foundation
import ItMkLibrary

@objc enum ReconcilableAccounts: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {

    // MARK: --- Cases
    case CashUKL    = 1
    case CashUSD    = 2
    case CashEUR    = 3
    case CashYEN    = 4
    case AMEX       = 5
    case VISA       = 6
    case BofSPV     = 7
    case BofSCA     = 8
    case LloydsC    = 9
    case BofSIASA   = 10
    case BofSISS    = 11
    case BofSYP     = 12
    case ItMkEquity = 13
    case unknown    = 99

    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }

    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }

    // MARK: --- Currency of Account
    var currency: Currency {
        switch self {
        case .CashUKL:    return .UKL
        case .CashUSD:    return .USD
        case .CashEUR:    return .EUR
        case .CashYEN:    return .JPY
        case .AMEX:       return .UKL
        case .VISA:       return .UKL
        case .BofSPV:     return .UKL
        case .BofSCA:     return .UKL
        case .LloydsC:    return .UKL
        case .BofSIASA:   return .UKL
        case .BofSISS:    return .UKL
        case .BofSYP:     return .UKL
        case .ItMkEquity: return .UKL
        case .unknown:    return .unknown
        }
    }

    // MARK: --- Human-readable Description
    var description: String {
        switch self {
        case .CashUKL:    return String(localized: "Cash UKL")
        case .CashUSD:    return String(localized: "Cash USD")
        case .CashEUR:    return String(localized: "Cash EUR")
        case .CashYEN:    return String(localized: "Cash YEN")
        case .AMEX:       return String(localized: "AMEX")
        case .VISA:       return String(localized: "VISA")
        case .BofSPV:     return String(localized: "BofS PV 82")
        case .BofSCA:     return String(localized: "BofS CA 64")
        case .LloydsC:    return String(localized: "Lloyds C 68")
        case .BofSIASA:   return String(localized: "BofS IASA 62")
        case .BofSISS:    return String(localized: "BofS ISS 43")
        case .BofSYP:     return String(localized: "BofS YP 06")
        case .ItMkEquity: return String(localized: "ItMk Equity")
        case .unknown:    return String(localized: "Unknown")
        }
    }

    // MARK: --- Code for Reconciliation
    var code: String {
        switch self {
        case .CashUKL:    return "CASH_UKL"
        case .CashUSD:    return "CASH_USD"
        case .CashEUR:    return "CASH_EUR"
        case .CashYEN:    return "CASH_YEN"
        case .AMEX:       return "AMEX"
        case .VISA:       return "VISA"
        case .BofSPV:     return "BOFS_PV_82"
        case .BofSCA:     return "BOFS_CA_64"
        case .LloydsC:    return "LLOYDS_C_68"
        case .BofSIASA:   return "BOFS_IASA_62"
        case .BofSISS:    return "BOFS_ISS_56"
        case .BofSYP:     return "BOFS_YP_57"
        case .ItMkEquity: return "ITMK_EQUITY"
        case .unknown:    return "UNKNOWN"
        }
    }

    // MARK: --- Int Conversion Helpers
    static func fromInt(_ i: Int) -> ReconcilableAccounts {
        switch i {
        case 1:          return .CashUKL
        case 2:          return .CashUSD
        case 3:          return .CashEUR
        case 4:          return .CashYEN
        case 5:          return .AMEX
        case 6:          return .VISA
        case 7:          return .BofSPV
        case 8:          return .BofSCA
        case 9:          return .LloydsC
        case 10:         return .BofSIASA
        case 11:         return .BofSISS
        case 12:         return .BofSYP
        case 13:         return .ItMkEquity
        case 99:         return .unknown
        default:         return .unknown
        }
    }

    // MARK: --- FromInt32
    static func fromInt32(_ i: Int32) -> ReconcilableAccounts {
        return ReconcilableAccounts.fromInt(Int(i))
    }
    
    // MARK: --- CurrencyCODE
    var currencyCode: String {
        switch self {
        case .CashUKL:    return "UKL"
        case .CashUSD:    return "USD"
        case .CashEUR:    return "EUR"
        case .CashYEN:    return "YEN"
        case .AMEX:       return "UKL"
        case .VISA:       return "UKL"
        case .BofSPV:     return "UKL"
        case .BofSCA:     return "UKL"
        case .LloydsC:    return "UKL"
        case .BofSIASA:   return "UKL"
        case .BofSISS:    return "UKL"
        case .BofSYP:     return "UKL"
        case .ItMkEquity: return "UKL"
        case .unknown:    return "UKL"
        }
    }
    
    // MARK: --- CSV Import
    var accountNumber: String {
        switch self {
        case .BofSPV:   return "00142182"
        case .BofSCA:   return "10077364"
        case .LloydsC:  return "30007768"
        case .BofSIASA: return "01511762"
        case .BofSISS:  return "01401443"
        case .BofSYP:   return "01931306"
        default: return ""
        }
    }
    
    static func fromAccountNumber(_ value: String) -> ReconcilableAccounts? {
        let normalised = value
            .trimmingCharacters(in: .whitespaces)
            .filter(\.isNumber)

        return Self.allCases.first {
            $0.accountNumber == normalised
        }
    }
}
