//
//  SettingsView.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: --- Sections
    enum SettingsSection: String, CaseIterable, Identifiable {
        case general = "General"
        case account = "Account"
        case advanced = "Advanced"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedSection: SettingsSection? = .general
    @State private var searchText: String = ""
    
    // Map each section to its control labels for search
    private var sectionControlLabels: [SettingsSection: [String]] {
        [
            .general: GeneralSettingsView.controlLabels,
            .account: AccountSettingsView.controlLabels,
            .advanced: AdvancedSettingsView.controlLabels
        ]
    }
    
    var filteredSections: [SettingsSection] {
        if searchText.isEmpty {
            return SettingsSection.allCases
        } else {
            return SettingsSection.allCases.filter { section in
                section.rawValue.localizedCaseInsensitiveContains(searchText) ||
                sectionControlLabels[section]?.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) == true
            }
        }
    }
    
    // MARK: --- Body
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 8) {
                TextField("Search Settings", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.top, .horizontal])
                
                List(filteredSections, selection: $selectedSection) { section in
                    Label(section.rawValue, systemImage: iconName(for: section))
                        .tag(section)
                }
                .listStyle(SidebarListStyle())
                
                Button("OK") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .frame(minWidth: 150)
        } detail: {
            Group {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
                case .account:
                    AccountSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                case .none:
                    Text("Select a section")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 500, minHeight: 250)
    }
    
    private func iconName(for section: SettingsSection) -> String {
        switch section {
        case .general: return "gearshape"
        case .account: return "person.crop.circle"
        case .advanced: return "wrench"
        }
    }
}

// MARK: --- Section Views

struct GeneralSettingsView: View {
    static let controlLabels: [String] = ["Enable Feature", "Refresh Interval"]
    @AppStorage("enableFeature") private var enableFeature = false
    @AppStorage("refreshInterval") private var refreshInterval = 5.0

    var body: some View {
        Form {
            Section(header: Text("General Settings")) {
                Toggle("Enable Feature", isOn: $enableFeature)
                    .accessibilityLabel("Enable Feature")
                
                HStack {
                    Text("Refresh Interval (seconds)")
                    Slider(value: $refreshInterval, in: 1...60, step: 1)
                    Text("\(Int(refreshInterval))")
                        .frame(width: 40, alignment: .leading)
                }
            }
        }
        .padding()
    }
}

struct AccountSettingsView: View {
    static let controlLabels: [String] = ["Username", "Email"]
    @AppStorage("username") private var username = ""
    @AppStorage("email") private var email = ""

    var body: some View {
        Form {
            Section(header: Text("Account Information")) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .accessibilityLabel("Username")
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .accessibilityLabel("Email")
            }
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    static let controlLabels: [String] = ["Enable Logging"]
    @AppStorage("enableLogging") private var enableLogging = false

    var body: some View {
        Form {
            Section(header: Text("Advanced")) {
                Toggle("Enable Logging", isOn: $enableLogging)
                    .accessibilityLabel("Enable Logging")
            }
        }
        .padding()
    }
}
