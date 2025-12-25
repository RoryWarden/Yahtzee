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
        potentialScores = ScoreCardMath.allPotentialScores(dice: dice)
        currentDiceIsYahtzee = ScoreCardMath.yahtzee(dice: dice) == 50
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
}

struct ScoreCardView: View {
    @Bindable var state: ScoreCardState
    var onCategorySelected: ((ScoreCategory) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("SCORE CARD")
                .font(.headline)
                .padding(.vertical, 8)

            Divider()

            // Upper Section
            SectionHeader(title: "UPPER SECTION")

            ForEach(ScoreCategory.upperSection) { category in
                ScoreRow(
                    category: category,
                    score: state.scores[category] ?? nil,
                    potentialScore: state.potentialScores[category],
                    onTap: { onCategorySelected?(category) }
                )
            }

            // Upper Section Totals
            TotalRow(label: "Upper Total", value: state.upperSectionTotal)
            TotalRow(label: "Bonus (63+)", value: state.upperBonus, highlight: state.upperBonus > 0)
            TotalRow(label: "Upper Total + Bonus", value: state.upperTotalWithBonus, isBold: true)

            Divider()
                .padding(.vertical, 4)

            // Lower Section
            SectionHeader(title: "LOWER SECTION")

            ForEach(ScoreCategory.lowerSection) { category in
                ScoreRow(
                    category: category,
                    score: state.scores[category] ?? nil,
                    potentialScore: state.potentialScores[category],
                    onTap: { onCategorySelected?(category) }
                )
            }

            Divider()
                .padding(.vertical, 4)

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
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
    }
}

struct ScoreRow: View {
    let category: ScoreCategory
    let score: Int?
    let potentialScore: Int?
    let onTap: () -> Void

    private var hasPotential: Bool {
        score == nil && potentialScore != nil
    }

    private var canScore: Bool {
        score == nil && (potentialScore ?? 0) > 0
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Category name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .foregroundColor(.primary)

                    Text(category.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Score display
                if let score = score {
                    // Already scored - show final value
                    Text("\(score)")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(minWidth: 36, alignment: .trailing)
                } else if let potential = potentialScore {
                    // Potential score - greyed out "would be" value
                    Text("\(potential)")
                        .fontWeight(.medium)
                        .foregroundColor(potential > 0 ? .blue : .gray)
                        .opacity(potential > 0 ? 0.8 : 0.5)
                        .frame(minWidth: 36, alignment: .trailing)
                } else {
                    // No potential yet (hasn't rolled)
                    Text("-")
                        .foregroundColor(.secondary)
                        .frame(minWidth: 36, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                hasPotential && canScore
                    ? Color.blue.opacity(0.08)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(score != nil)

        Divider()
            .padding(.leading, 12)
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
                .foregroundColor(highlight ? .green : .primary)

            Spacer()

            Text("\(value)")
                .font(isGrandTotal ? .headline : .subheadline)
                .fontWeight(isBold ? .semibold : .regular)
                .foregroundColor(highlight ? .green : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isGrandTotal ? Color.gray.opacity(0.1) : Color.clear)
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
