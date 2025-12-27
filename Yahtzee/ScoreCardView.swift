//
//  ScoreCardView.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import SwiftUI

@Observable
class ScoreCardState {
    var scores: [ScoreCategory: Int?] = [:]
    var potentialScores: [ScoreCategory: Int] = [:]
    var yahtzeeBonusCount: Int = 0
    private var currentDiceIsYahtzee: Bool = false
    private var yahtzeeValue: Int = 0  // The die value of the current yahtzee (1-6)
    private var currentDice: [Int] = []

    init() {
        for category in ScoreCategory.allCases {
            scores[category] = nil
        }
    }

    var upperSectionTotal: Int {
        ScoreCategory.upperSection.compactMap { scores[$0] ?? nil }.reduce(0, +)
    }

    var upperBonus: Int {
        ScoreCardMath.upperBonus(upperTotal: upperSectionTotal)
    }

    var upperTotalWithBonus: Int {
        upperSectionTotal + upperBonus
    }

    var lowerSectionTotal: Int {
        ScoreCategory.lowerSection.compactMap { scores[$0] ?? nil }.reduce(0, +)
    }

    var yahtzeeBonus: Int {
        yahtzeeBonusCount * 100
    }

    var grandTotal: Int {
        upperTotalWithBonus + lowerSectionTotal + yahtzeeBonus
    }

    var isComplete: Bool {
        ScoreCategory.allCases.allSatisfy { isScored($0) }
    }

    func isScored(_ category: ScoreCategory) -> Bool {
        scores[category] != nil
    }

    func score(category: ScoreCategory, value: Int) {
        guard !isScored(category) else { return }

        // Check for Yahtzee bonus: if rolling a Yahtzee and Yahtzee box already has 50
        if currentDiceIsYahtzee && category != .yahtzee {
            if let yahtzeeScore = scores[.yahtzee], yahtzeeScore == 50 {
                yahtzeeBonusCount += 1
            }
        }

        scores[category] = value
    }

    func updatePotentialScores(dice: [Int]) {
        currentDice = dice
        currentDiceIsYahtzee = ScoreCardMath.yahtzee(dice: dice) == 50
        yahtzeeValue = currentDiceIsYahtzee ? dice[0] : 0

        // Calculate base potential scores
        var potential = ScoreCardMath.allPotentialScores(dice: dice)

        // Apply Joker rules if enabled and this is a bonus Yahtzee
        if SettingsManager.shared.jokerRulesEnabled && yahtzeeBonusAvailable {
            // Joker can score fixed values for Full House, Small/Large Straight
            potential[.fullHouse] = 25
            potential[.smallStraight] = 30
            potential[.largeStraight] = 40
        }

        potentialScores = potential
    }

    func clearPotentialScores() {
        potentialScores = [:]
        currentDiceIsYahtzee = false
    }

    func reset() {
        for category in ScoreCategory.allCases {
            scores[category] = nil
        }
        potentialScores = [:]
        yahtzeeBonusCount = 0
        currentDiceIsYahtzee = false
    }

    func unscore(category: ScoreCategory) {
        scores[category] = nil
    }

    /// Progress toward the 63-point upper bonus threshold
    var upperBonusProgress: Int {
        upperSectionTotal
    }

    var upperBonusNeeded: Int {
        max(0, 63 - upperSectionTotal)
    }

    /// True when rolling a Yahtzee and eligible for bonus (Yahtzee already scored as 50)
    var yahtzeeBonusAvailable: Bool {
        currentDiceIsYahtzee && scores[.yahtzee] == 50
    }

    /// Returns whether a category can be selected under current rules
    /// When Joker rules are enabled and a bonus Yahtzee is rolled, selection is restricted
    func isCategoryValidForSelection(_ category: ScoreCategory) -> Bool {
        // Can't select already scored categories
        guard !isScored(category) else { return false }

        // If Joker rules disabled, any unscored category with a potential score is valid
        guard SettingsManager.shared.jokerRulesEnabled else { return true }

        // If not a bonus Yahtzee situation, normal rules apply
        guard yahtzeeBonusAvailable else { return true }

        // JOKER RULES: Priority-based selection
        let matchingUpperCategory = ScoreCategory.upperCategory(for: yahtzeeValue)

        // 1. If matching upper section is open, MUST use it
        if let upperCat = matchingUpperCategory, !isScored(upperCat) {
            return category == upperCat
        }

        // 2. If matching upper is filled, can use any open lower section
        let openLowerCategories = ScoreCategory.lowerSection.filter { !isScored($0) }
        if !openLowerCategories.isEmpty {
            return openLowerCategories.contains(category)
        }

        // 3. If all lower filled, can use any open upper section (scores 0)
        let openUpperCategories = ScoreCategory.upperSection.filter { !isScored($0) }
        return openUpperCategories.contains(category)
    }

    /// Message explaining why Joker rules restrict category selection
    var jokerRulesMessage: String? {
        guard SettingsManager.shared.jokerRulesEnabled && yahtzeeBonusAvailable else { return nil }

        let matchingUpperCategory = ScoreCategory.upperCategory(for: yahtzeeValue)

        if let upperCat = matchingUpperCategory, !isScored(upperCat) {
            return "Joker Rule: Must score in \(upperCat.rawValue)"
        }

        let openLowerCategories = ScoreCategory.lowerSection.filter { !isScored($0) }
        if !openLowerCategories.isEmpty {
            return "Joker Rule: Score in any open lower section"
        }

        return "Joker Rule: Score 0 in any open upper section"
    }
}

struct ScoreCardView: View {
    @Bindable var state: ScoreCardState
    var onCategorySelected: ((ScoreCategory) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("SCORE CARD")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 6)

            Divider()

            // Upper Section
            SectionHeader(title: "UPPER SECTION")

            ForEach(ScoreCategory.upperSection) { category in
                ScoreRow(
                    category: category,
                    score: state.scores[category] ?? nil,
                    potentialScore: state.potentialScores[category],
                    isValidForSelection: state.isCategoryValidForSelection(category),
                    onTap: { onCategorySelected?(category) }
                )
            }

            // Upper bonus progress indicator
            UpperBonusProgressView(
                current: state.upperBonusProgress,
                hasBonus: state.upperBonus > 0
            )

            // Upper Section Totals
            TotalRow(label: "Upper Total", value: state.upperSectionTotal)
            TotalRow(label: "Bonus (63+)", value: state.upperBonus, highlight: state.upperBonus > 0)
            TotalRow(label: "Upper Total + Bonus", value: state.upperTotalWithBonus, isBold: true)

            Divider()
                .padding(.vertical, 2)

            // Lower Section
            SectionHeader(title: "LOWER SECTION")

            ForEach(ScoreCategory.lowerSection) { category in
                ScoreRow(
                    category: category,
                    score: state.scores[category] ?? nil,
                    potentialScore: state.potentialScores[category],
                    isValidForSelection: state.isCategoryValidForSelection(category),
                    onTap: { onCategorySelected?(category) }
                )
            }

            Divider()
                .padding(.vertical, 2)

            // Yahtzee Bonus Available indicator
            if state.yahtzeeBonusAvailable {
                YahtzeeBonusBanner(jokerMessage: state.jokerRulesMessage)
            }

            // Yahtzee Bonus
            if state.yahtzeeBonusCount > 0 {
                TotalRow(
                    label: "Yahtzee Bonus (\(state.yahtzeeBonusCount) x 100)",
                    value: state.yahtzeeBonus,
                    highlight: true
                )
            }

            // Grand Total
            TotalRow(label: "Lower Total", value: state.lowerSectionTotal)
            TotalRow(label: "Upper Total + Bonus", value: state.upperTotalWithBonus)
            if state.yahtzeeBonusCount > 0 {
                TotalRow(label: "Yahtzee Bonus", value: state.yahtzeeBonus, highlight: true)
            }
            TotalRow(label: "GRAND TOTAL", value: state.grandTotal, isBold: true, isGrandTotal: true)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Theme.sectionHeader)
    }
}

struct ScoreRow: View {
    let category: ScoreCategory
    let score: Int?
    let potentialScore: Int?
    let isValidForSelection: Bool
    let onTap: () -> Void

    private var isScored: Bool {
        score != nil
    }

    private var hasPotential: Bool {
        score == nil && potentialScore != nil
    }

    private var canScore: Bool {
        score == nil && (potentialScore ?? 0) > 0 && isValidForSelection
    }

    private var isDisabledByJoker: Bool {
        score == nil && potentialScore != nil && !isValidForSelection
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Category name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .foregroundColor(isScored ? Theme.scoredText : .primary)

                    Text(category.description)
                        .font(.caption2)
                        .foregroundColor(isScored ? Theme.scoredText.opacity(0.7) : .secondary)
                }

                Spacer()

                // Score display
                if let score = score {
                    // Already scored - show final value in blue
                    Text("\(score)")
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.scoredText)
                        .frame(minWidth: 36, alignment: .trailing)
                } else if let potential = potentialScore {
                    // Potential score - orange for positive, gray for zero
                    Text("\(potential)")
                        .fontWeight(.semibold)
                        .foregroundColor(potential > 0 ? Theme.potentialScore : Theme.zeroPotential)
                        .frame(minWidth: 36, alignment: .trailing)
                } else {
                    // No potential yet (hasn't rolled)
                    Text("-")
                        .foregroundColor(.secondary)
                        .frame(minWidth: 36, alignment: .trailing)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isScored
                    ? Theme.scored
                    : (canScore ? Theme.accentLight.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle())
            .opacity(isDisabledByJoker ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(score != nil || isDisabledByJoker)

        Divider()
            .padding(.leading, 10)
    }
}

struct TotalRow: View {
    let label: String
    let value: Int
    var highlight: Bool = false
    var isBold: Bool = false
    var isGrandTotal: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isGrandTotal ? .headline : .subheadline)
                .fontWeight(isBold ? .semibold : .regular)
                .foregroundColor(highlight ? Theme.success : (isGrandTotal ? Theme.primaryDark : .primary))

            Spacer()

            Text("\(value)")
                .font(isGrandTotal ? .headline : .subheadline)
                .fontWeight(isBold ? .semibold : .regular)
                .foregroundColor(highlight ? Theme.success : (isGrandTotal ? Theme.primaryDark : .primary))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(isGrandTotal ? Theme.primaryLight : Color.clear)
    }
}

struct UpperBonusProgressView: View {
    let current: Int
    let hasBonus: Bool
    private let target = 63

    var body: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(hasBonus ? Theme.success : Theme.primary)
                        .frame(
                            width: min(CGFloat(current) / CGFloat(target) * geometry.size.width, geometry.size.width),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Label
            HStack {
                if hasBonus {
                    Label("Bonus earned!", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.success)
                } else {
                    Text("\(current)/\(target) toward bonus")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(target - current) more needed")
                        .font(.caption2)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

struct YahtzeeBonusBanner: View {
    var jokerMessage: String?
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)

                Image(systemName: "star.fill")
                    .foregroundColor(Theme.accent)
                    .scaleEffect(isAnimating ? 1.0 : 1.2)

                Text("YAHTZEE BONUS!")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent)

                Text("+100")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(Theme.success)

                Image(systemName: "star.fill")
                    .foregroundColor(Theme.accent)
                    .scaleEffect(isAnimating ? 1.0 : 1.2)

                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
            }

            if let message = jokerMessage {
                Text(message)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.primaryDark)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Theme.accentLight, Theme.accent.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.accent, lineWidth: 2)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    let state = ScoreCardState()
    state.scores[.ones] = 3
    state.scores[.threes] = 9
    state.scores[.fullHouse] = 25
    state.potentialScores = [.twos: 4, .fours: 8, .chance: 18]

    return ScrollView {
        ScoreCardView(state: state) { category in
            print("Selected: \(category.rawValue)")
        }
    }
}
