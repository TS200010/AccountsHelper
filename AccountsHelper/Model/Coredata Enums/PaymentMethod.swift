//
//  PaymentMethod.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/09/2024.
//

import Foundation
import ItMkLibrary


@objc enum PaymentMethod: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {

    case CashGBP        = 1
    case CashUSD        = 2
    case CashEUR        = 3
    case CashYEN        = 4
    case AMEX           = 5
    case VISA           = 6
    case bankOfScotland = 7
    case unknown        = 99

    // Initialize from string
    init(_ s: String) {
        self = PaymentMethod.fromString(s)
    }

    // Raw value as string
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    // Currency of the paymentMethod
    var currency: Currency {
        switch self {
        case .CashGBP:        return .GBP
        case .CashUSD:        return .USD
        case .CashEUR:        return .EUR
        case .CashYEN:        return .JPY
        case .AMEX:           return .GBP
        case .VISA:           return .GBP
        case .bankOfScotland: return .GBP
        case .unknown:        return .unknown
        }
    }

    // Human-readable description
    var description: String {
        switch self {
        case .CashGBP:        return String(localized: "Cash GBP")
        case .CashUSD:        return String(localized: "Cash USD")
        case .CashEUR:        return String(localized: "Cash EUR")
        case .CashYEN:        return String(localized: "Cash YEN")
        case .AMEX:           return String(localized: "AMEX")
        case .VISA:           return String(localized: "VISA")
        case .bankOfScotland: return String(localized: "BankOfS")
        case .unknown:        return String(localized: "Unknown")
        }
    }
    
    // MARK: --- NOTE: code is used in the periodKey in Reconciliation.
    // ... Changing this such that existing codes change will break reconciliation
    var code: String {
        switch self {
        case .CashGBP: return "CASH_GBP"
        case .CashUSD: return "CASH_USD"
        case .CashEUR: return "CASH_EUR"
        case .CashYEN: return "CASH_YEN"
        case .AMEX: return "AMEX"
        case .VISA: return "VISA"
        case .bankOfScotland: return "BANK_SCOT"
        case .unknown: return "UNKNOWN"
        }
    }

    // Convert from string
    static func fromString(_ s: String) -> PaymentMethod {
        switch s {
        case "Cash GBP":       return .CashGBP
        case "Cash USD":       return .CashUSD
        case "Cash EUR":       return .CashEUR
        case "Cash YEN":       return .CashYEN
        case "AMEX":           return .AMEX
        case "VISA":           return .VISA
        case "BankOfS":        return .bankOfScotland
        default:               return .unknown
        }
    }

    // Convert from Int
    static func fromInt(_ i: Int) -> PaymentMethod {
        switch i {
        case 1: return .CashGBP
        case 2: return .CashUSD
        case 3: return .CashEUR
        case 4: return .CashYEN
        case 5: return .AMEX
        case 6: return .VISA
        case 7: return .bankOfScotland
        default: return .unknown
        }
    }

    // Convert from Int32
    static func fromInt32(_ i: Int32) -> PaymentMethod {
        return PaymentMethod.fromInt(Int(i))
    }
}


//@objc enum PaymentMethod: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
//    
//    case CashGBP        = 1
//    case AMEX           = 2
//    case VISA           = 3
//    case bankOfScotland = 4
//    case unknown        = 99
//    
//    init( _ s: String ) {
//        self = PaymentMethod.fromString( s )
//    }
//    
//    func rawValueAsString() -> String {
//        return self.rawValue.description
//    }
//    
//    var description: String {
//        switch self {
//            case .CASH:             return String( localized: "Cash" )
//            case .AMEX:             return String( localized: "AMEX" )
//            case .VISA:             return String( localized: "VISA" )
//            case .bankOfScotland:   return String( localized: "BankOfS" )
//            case .unknown:          return String( localized: "Unknown" )
//        }
//    }
//    
//    static func fromString( _ s: String ) -> PaymentMethod {
//        switch s {
//        case "Cash":          return Self.CASH
//        case "AMEX":          return Self.AMEX
//        case "VISA":          return Self.VISA
//        case "BankOfS":       return Self.bankOfScotland
//        default:              return Self.unknown
//        }
//    }
//
//    
//    // TODO: Not sure we need these
//    
//    static func fromInt( _ i: Int ) -> PaymentMethod {
//        
//        switch i {
//            case 1:  return Self.CASH
//            case 2:  return Self.AMEX
//            case 3:  return Self.VISA
//            case 4:  return Self.bankOfScotland
//            default: return Self.unknown
//        }
//    }
//    
//    static func fromInt32( _ i: Int32 ) -> PaymentMethod {
//        
//        return PaymentMethod.fromInt( Int( i ) )
//    }
//}
