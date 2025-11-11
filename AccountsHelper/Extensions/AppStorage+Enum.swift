//
//  AppStorage+Enum.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import SwiftUI

extension AppStorage where Value == String {
    init<Enum: RawRepresentable>(
        _ key: String,
        store: UserDefaults? = nil,
        defaultValue: Enum
    ) where Enum.RawValue == String {
        self.init(wrappedValue: defaultValue.rawValue, key, store: store)
    }
}

@propertyWrapper
struct AppStorageEnum<Enum: RawRepresentable & CaseIterable>: DynamicProperty where Enum.RawValue == String {
    @AppStorage private var rawValue: String
    var wrappedValue: Enum {
        get { Enum(rawValue: rawValue) ?? Enum.allCases.first! }
        nonmutating set { rawValue = newValue.rawValue }
    }

    init(_ key: String, defaultValue: Enum) {
        _rawValue = AppStorage(wrappedValue: defaultValue.rawValue, key)
    }
}
