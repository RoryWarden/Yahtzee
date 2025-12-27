//
//  Theme.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/26/25.
//
//  Centralized color theme for consistent styling across macOS and iOS.
//  Supports multiple theme options including custom user-defined themes.
//

import SwiftUI

struct Theme {
    private static var currentTheme: AppTheme {
        SettingsManager.shared.appTheme
    }

    private static var customTheme: CustomTheme? {
        SettingsManager.shared.selectedCustomTheme
    }

    private static func darken(_ color: Color, by amount: Double = 0.25) -> Color {
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return color
        }
        return Color(
            red: max(0, Double(components[0]) - amount),
            green: max(0, Double(components[1]) - amount),
            blue: max(0, Double(components[2]) - amount)
        )
    }

    private static func lighten(_ color: Color, by amount: Double = 0.3) -> Color {
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return color
        }
        return Color(
            red: min(1, Double(components[0]) + amount),
            green: min(1, Double(components[1]) + amount),
            blue: min(1, Double(components[2]) + amount)
        )
    }

    /// Main brand color - used for primary buttons, current player, completed items
    static var primary: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 0.2, green: 0.5, blue: 0.85)
        case .redBlue:
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .greenYellow:
            return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .custom:
            return customTheme?.primaryColor ?? Color(red: 0.2, green: 0.5, blue: 0.85)
        }
    }

    /// Darker primary for gradients and emphasis
    static var primaryDark: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 0.15, green: 0.35, blue: 0.65)
        case .redBlue:
            return Color(red: 0.6, green: 0.1, blue: 0.1)
        case .greenYellow:
            return Color(red: 0.1, green: 0.4, blue: 0.25)
        case .custom:
            return darken(customTheme?.primaryColor ?? Color(red: 0.2, green: 0.5, blue: 0.85))
        }
    }

    /// Lighter primary for backgrounds
    static var primaryLight: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 0.85, green: 0.92, blue: 1.0)
        case .redBlue:
            return Color(red: 1.0, green: 0.9, blue: 0.9)
        case .greenYellow:
            return Color(red: 0.85, green: 0.95, blue: 0.9)
        case .custom:
            return lighten(customTheme?.primaryColor ?? Color(red: 0.2, green: 0.5, blue: 0.85), by: 0.5)
        }
    }

    /// Accent color - used for potential scores, highlights, calls-to-action
    static var accent: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .redBlue:
            return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .greenYellow:
            return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .custom:
            return customTheme?.accentColor ?? Color(red: 1.0, green: 0.55, blue: 0.1)
        }
    }

    /// Darker accent for text on light backgrounds
    static var accentDark: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 0.9, green: 0.4, blue: 0.0)
        case .redBlue:
            return Color(red: 0.1, green: 0.25, blue: 0.6)
        case .greenYellow:
            return Color(red: 0.8, green: 0.6, blue: 0.0)
        case .custom:
            return darken(customTheme?.accentColor ?? Color(red: 1.0, green: 0.55, blue: 0.1), by: 0.15)
        }
    }

    /// Lighter accent for backgrounds
    static var accentLight: Color {
        switch currentTheme {
        case .blueOrange:
            return Color(red: 1.0, green: 0.9, blue: 0.8)
        case .redBlue:
            return Color(red: 0.85, green: 0.9, blue: 1.0)
        case .greenYellow:
            return Color(red: 1.0, green: 0.95, blue: 0.8)
        case .custom:
            return lighten(customTheme?.accentColor ?? Color(red: 1.0, green: 0.55, blue: 0.1), by: 0.4)
        }
    }

    /// Completed/scored category background
    static var scored: Color { primaryLight }

    /// Unscored category background
    static let unscored = Color.clear

    /// Potential score that can be selected (positive value)
    static var potentialScore: Color { accent }

    /// Potential score of zero
    static let zeroPotential = Color.gray.opacity(0.5)

    /// Scored value text
    static var scoredText: Color { primaryDark }

    /// Dice table/felt background
    static let diceTable = Color(red: 0.15, green: 0.35, blue: 0.25)

    /// Dice table lighter variant
    static let diceTableLight = Color(red: 0.2, green: 0.45, blue: 0.35)

    /// Held dice indicator
    static var diceHeld: Color { accent }

    /// Roll button
    static var rollButton: Color { primary }

    /// Current player highlight
    static var currentPlayer: Color { primary }

    /// Other players
    static let otherPlayer = Color.gray.opacity(0.3)

    /// Success/bonus achieved
    static let success = Color(red: 0.2, green: 0.7, blue: 0.3)

    /// Warning/needs attention
    static var warning: Color { accent }

    /// Section headers
    static let sectionHeader = Color.gray.opacity(0.15)

    /// Main menu gradient top
    static var menuGradientTop: Color { primary }

    /// Main menu gradient bottom
    static var menuGradientBottom: Color { primaryDark }

    /// Menu button background
    static let menuButton = Color.white

    /// Menu button text
    static var menuButtonText: Color { primary }

    /// Secondary menu button (translucent)
    static let menuButtonSecondary = Color.white.opacity(0.2)

    /// Yahtzee celebration colors
    static var celebrationColors: [Color] {
        [accent, primary, .yellow, success, .white, accentLight, primaryLight]
    }

    /// Main menu background gradient
    static var menuGradient: LinearGradient {
        LinearGradient(
            colors: [menuGradientTop, menuGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Dice table gradient
    static var diceTableGradient: LinearGradient {
        LinearGradient(
            colors: [diceTableLight, diceTable],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Primary button gradient
    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    /// Apply scored category styling
    func scoredStyle() -> some View {
        self
            .background(Theme.scored)
    }

    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.primaryButtonGradient)
            )
    }

    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.menuButtonSecondary)
            )
    }
}
