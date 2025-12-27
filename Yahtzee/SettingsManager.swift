//
//  SettingsManager.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/26/25.
//
//  Manages app settings with persistence.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case blueOrange = "Blue & Orange"
    case redBlue = "Red & Blue"
    case greenYellow = "Green & Yellow"
    case custom = "Custom"
}

enum DarkModeOption: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct CustomTheme: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var primaryRed: Double
    var primaryGreen: Double
    var primaryBlue: Double
    var accentRed: Double
    var accentGreen: Double
    var accentBlue: Double

    var primaryColor: Color {
        Color(red: primaryRed, green: primaryGreen, blue: primaryBlue)
    }

    var accentColor: Color {
        Color(red: accentRed, green: accentGreen, blue: accentBlue)
    }

    init(id: UUID = UUID(), name: String, primaryColor: Color, accentColor: Color) {
        self.id = id
        self.name = name

        // Extract RGB components from colors
        let primaryComponents = primaryColor.cgColor?.components ?? [0.2, 0.5, 0.85, 1.0]
        self.primaryRed = Double(primaryComponents[0])
        self.primaryGreen = Double(primaryComponents[1])
        self.primaryBlue = Double(primaryComponents[2])

        let accentComponents = accentColor.cgColor?.components ?? [1.0, 0.55, 0.1, 1.0]
        self.accentRed = Double(accentComponents[0])
        self.accentGreen = Double(accentComponents[1])
        self.accentBlue = Double(accentComponents[2])
    }
}

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    var soundEnabled: Bool {
        didSet { save() }
    }

    var appTheme: AppTheme {
        didSet { save() }
    }

    var darkModeOption: DarkModeOption {
        didSet { save() }
    }

    var jokerRulesEnabled: Bool {
        didSet { save() }
    }

    var customThemes: [CustomTheme] {
        didSet { save() }
    }

    var selectedCustomThemeId: UUID? {
        didSet { save() }
    }

    var selectedCustomTheme: CustomTheme? {
        guard let id = selectedCustomThemeId else { return nil }
        return customThemes.first { $0.id == id }
    }

    private let defaults = UserDefaults.standard
    private let soundKey = "YahtzeeSoundEnabled"
    private let themeKey = "YahtzeeAppTheme"
    private let darkModeKey = "YahtzeeDarkMode"
    private let jokerKey = "YahtzeeJokerRules"
    private let customThemesKey = "YahtzeeCustomThemes"
    private let selectedCustomThemeKey = "YahtzeeSelectedCustomTheme"

    private init() {
        // Load saved settings or use defaults
        self.soundEnabled = defaults.object(forKey: soundKey) as? Bool ?? true

        if let themeString = defaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeString) {
            self.appTheme = theme
        } else {
            self.appTheme = .blueOrange
        }

        if let darkModeString = defaults.string(forKey: darkModeKey),
           let darkMode = DarkModeOption(rawValue: darkModeString) {
            self.darkModeOption = darkMode
        } else {
            self.darkModeOption = .system
        }

        self.jokerRulesEnabled = defaults.object(forKey: jokerKey) as? Bool ?? false

        // Load custom themes
        if let data = defaults.data(forKey: customThemesKey),
           let themes = try? JSONDecoder().decode([CustomTheme].self, from: data) {
            self.customThemes = themes
        } else {
            self.customThemes = []
        }

        // Load selected custom theme ID
        if let idString = defaults.string(forKey: selectedCustomThemeKey),
           let id = UUID(uuidString: idString) {
            self.selectedCustomThemeId = id
        } else {
            self.selectedCustomThemeId = nil
        }
    }

    private func save() {
        defaults.set(soundEnabled, forKey: soundKey)
        defaults.set(appTheme.rawValue, forKey: themeKey)
        defaults.set(darkModeOption.rawValue, forKey: darkModeKey)
        defaults.set(jokerRulesEnabled, forKey: jokerKey)

        // Save custom themes
        if let data = try? JSONEncoder().encode(customThemes) {
            defaults.set(data, forKey: customThemesKey)
        }

        // Save selected custom theme ID
        if let id = selectedCustomThemeId {
            defaults.set(id.uuidString, forKey: selectedCustomThemeKey)
        } else {
            defaults.removeObject(forKey: selectedCustomThemeKey)
        }
    }

    var colorScheme: ColorScheme? {
        switch darkModeOption {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func addCustomTheme(_ theme: CustomTheme) {
        customThemes.append(theme)
        selectedCustomThemeId = theme.id
        appTheme = .custom
    }

    func deleteCustomTheme(_ theme: CustomTheme) {
        customThemes.removeAll { $0.id == theme.id }
        if selectedCustomThemeId == theme.id {
            selectedCustomThemeId = customThemes.first?.id
            if customThemes.isEmpty {
                appTheme = .blueOrange
            }
        }
    }

    func selectCustomTheme(_ theme: CustomTheme) {
        selectedCustomThemeId = theme.id
        appTheme = .custom
    }
}
