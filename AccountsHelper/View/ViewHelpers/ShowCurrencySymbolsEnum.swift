//
//  ShowCurrencySymbolsEnum.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation

enum ShowCurrencySymbolsEnum: String, CaseIterable {
    case always
    case never
    case whenNotUKL
    
    func show( currency: Currency ) -> Bool {
        return self == .always || ( self == .whenNotUKL && currency.code != "UKL" )
    }
    
    func next() -> ShowCurrencySymbolsEnum {
        let all = Self.allCases
        if let i = all.firstIndex(of: self) {
            let nextIndex = all.index(after: i)
            return nextIndex < all.endIndex ? all[nextIndex] : all.first!
        }
        return self
    }
    
    var iconName: String {
        switch self {
        case .always: return "sterlingsign.circle.fill"
        case .never: return "xmark.circle"
        case .whenNotUKL: return "sterlingsign.square"
        }
    }
    
}
