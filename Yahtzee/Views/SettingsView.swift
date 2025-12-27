//
//  SettingsView.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/26/25.
//
//  Settings panel for app configuration.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCustomThemeCreator = false
    @State private var showClearDataConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Sound Settings
                    SettingsSection(title: "Sound", icon: "speaker.wave.2.fill") {
                        Toggle("Sound Effects", isOn: $settings.soundEnabled)
                            .toggleStyle(.switch)
                    }

                    // Theme Settings
                    SettingsSection(title: "Theme", icon: "paintpalette.fill") {
                        // Built-in themes
                        ForEach([AppTheme.blueOrange, .redBlue, .greenYellow], id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: settings.appTheme == theme
                            ) {
                                settings.appTheme = theme
                            }
                        }

                        // Custom themes
                        ForEach(settings.customThemes) { customTheme in
                            CustomThemeRow(
                                customTheme: customTheme,
                                isSelected: settings.appTheme == .custom && settings.selectedCustomThemeId == customTheme.id,
                                onSelect: {
                                    settings.selectCustomTheme(customTheme)
                                },
                                onDelete: {
                                    settings.deleteCustomTheme(customTheme)
                                }
                            )
                        }

                        // Add custom theme button
                        Button {
                            showCustomThemeCreator = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4]))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "plus")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Text("Create Custom Theme")
                                    .foregroundColor(.secondary)

                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    // Dark Mode Settings
                    SettingsSection(title: "Appearance", icon: "circle.lefthalf.filled") {
                        Picker("Mode", selection: $settings.darkModeOption) {
                            ForEach(DarkModeOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Joker Rules
                    SettingsSection(title: "Game Rules", icon: "dice.fill") {
                        Toggle("Joker Rules", isOn: $settings.jokerRulesEnabled)
                            .toggleStyle(.switch)

                        Text("When enabled, rolling a second Yahtzee follows official \"Joker Rules\": you must score in the matching upper section if available, or use the Yahtzee as a \"wild\" for Full House, Straights, etc. This is the official Hasbro rule since 1961.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    // Data Management
                    SettingsSection(title: "Data", icon: "externaldrive.fill") {
                        Button {
                            showClearDataConfirmation = true
                        } label: {
                            HStack {
                                Text("Clear All Data")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Removes all game history, high scores, and player statistics. This cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 600)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .alert("Clear All Data?", isPresented: $showClearDataConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                GameHistoryManager.shared.clearHistory()
            }
        } message: {
            Text("This will permanently delete all game history, high scores, and player statistics.")
        }
        .sheet(isPresented: $showCustomThemeCreator) {
            CustomThemeCreatorView { newTheme in
                settings.addCustomTheme(newTheme)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(Theme.primary)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
}

struct ThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    private var primaryColor: Color {
        switch theme {
        case .blueOrange: return Color(red: 0.2, green: 0.5, blue: 0.85)
        case .redBlue: return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .greenYellow: return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .custom: return Color.gray
        }
    }

    private var accentColor: Color {
        switch theme {
        case .blueOrange: return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .redBlue: return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .greenYellow: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .custom: return Color.gray
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Color preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(accentColor)
                        .frame(width: 24, height: 24)
                }

                Text(theme.rawValue)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.success)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? primaryColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomThemeRow: View {
    let customTheme: CustomTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    // Color preview
                    HStack(spacing: 4) {
                        Circle()
                            .fill(customTheme.primaryColor)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(customTheme.accentColor)
                            .frame(width: 24, height: 24)
                    }

                    Text(customTheme.name)
                        .foregroundColor(.primary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.success)
                    }
                }
            }
            .buttonStyle(.plain)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? customTheme.primaryColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? customTheme.primaryColor : Color.clear, lineWidth: 2)
        )
    }
}

struct CustomThemeCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeName: String = ""
    @State private var primaryColor: Color = Color(red: 0.5, green: 0.3, blue: 0.7)
    @State private var accentColor: Color = Color(red: 0.9, green: 0.6, blue: 0.2)

    let onSave: (CustomTheme) -> Void

    private var canSave: Bool {
        !themeName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Text("New Theme")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    let theme = CustomTheme(
                        name: themeName.trimmingCharacters(in: .whitespaces),
                        primaryColor: primaryColor,
                        accentColor: accentColor
                    )
                    onSave(theme)
                    dismiss()
                }
                .disabled(!canSave)
            }
            .padding()

            Divider()

            VStack(spacing: 24) {
                // Theme name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("My Custom Theme", text: $themeName)
                        .textFieldStyle(.roundedBorder)
                }

                // Primary color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Color")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Used for buttons, current player, completed categories")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ColorPicker("Primary", selection: $primaryColor, supportsOpacity: false)
                        .labelsHidden()
                }

                // Accent color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accent Color")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Used for potential scores, highlights, held dice")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ColorPicker("Accent", selection: $accentColor, supportsOpacity: false)
                        .labelsHidden()
                }

                Divider()

                // Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 16) {
                        // Primary preview
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(primaryColor)
                                .frame(width: 60, height: 40)
                            Text("Primary")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Accent preview
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor)
                                .frame(width: 60, height: 40)
                            Text("Accent")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Combined preview
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [primaryColor, primaryColor.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 80, height: 40)

                                Text("PLAY")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text("Button")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Score preview
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("12")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(accentColor)
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 12, height: 12)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(accentColor.opacity(0.2))
                            )
                            Text("Score")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        #if os(macOS)
        .frame(width: 350, height: 450)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

#Preview {
    SettingsView()
}
