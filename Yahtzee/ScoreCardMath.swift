//
//  ScoreCardMath.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import Foundation

struct ScoreCardMath {
    /// Calculates score for a specific die value (Ones through Sixes)
    static func upperScore(for value: Int, dice: [Int]) -> Int {
        dice.filter { $0 == value }.reduce(0, +)
    }

    static func ones(dice: [Int]) -> Int { upperScore(for: 1, dice: dice) }
    static func twos(dice: [Int]) -> Int { upperScore(for: 2, dice: dice) }
    static func threes(dice: [Int]) -> Int { upperScore(for: 3, dice: dice) }
    static func fours(dice: [Int]) -> Int { upperScore(for: 4, dice: dice) }
    static func fives(dice: [Int]) -> Int { upperScore(for: 5, dice: dice) }
    static func sixes(dice: [Int]) -> Int { upperScore(for: 6, dice: dice) }

    /// Upper bonus threshold (63 points needed for bonus)
    static let upperBonusThreshold = 63

    /// Upper bonus value (35 points)
    static let upperBonusValue = 35

    /// Calculates the upper bonus (35 if upper total >= 63, otherwise 0)
    static func upperBonus(upperTotal: Int) -> Int {
        upperTotal >= upperBonusThreshold ? upperBonusValue : 0
    }
	
    /// Returns a dictionary of die face counts
    static func diceCounts(_ dice: [Int]) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for die in dice {
            counts[die, default: 0] += 1
        }
        return counts
    }

    /// Three of a Kind: Sum of all dice if at least 3 are the same
    static func threeOfAKind(dice: [Int]) -> Int {
        let counts = diceCounts(dice)
        if counts.values.contains(where: { $0 >= 3 }) {
            return dice.reduce(0, +)
        }
        return 0
    }

    /// Four of a Kind: Sum of all dice if at least 4 are the same
    static func fourOfAKind(dice: [Int]) -> Int {
        let counts = diceCounts(dice)
        if counts.values.contains(where: { $0 >= 4 }) {
            return dice.reduce(0, +)
        }
        return 0
    }

    /// Full House: 25 points if 3 of one kind and 2 of another
    static func fullHouse(dice: [Int]) -> Int {
        let counts = diceCounts(dice)
        let values = Array(counts.values).sorted()
        if values == [2, 3] {
            return 25
        }
        return 0
    }

    /// Small Straight: 30 points if 4 sequential dice
    static func smallStraight(dice: [Int]) -> Int {
        let uniqueSorted = Set(dice).sorted()
        let straights = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]
        for straight in straights {
            if straight.allSatisfy({ uniqueSorted.contains($0) }) {
                return 30
            }
        }
        return 0
    }

    /// Large Straight: 40 points if 5 sequential dice
    static func largeStraight(dice: [Int]) -> Int {
        let sorted = dice.sorted()
        if sorted == [1, 2, 3, 4, 5] || sorted == [2, 3, 4, 5, 6] {
            return 40
        }
        return 0
    }

    /// Yahtzee: 50 points if all 5 dice are the same
    static func yahtzee(dice: [Int]) -> Int {
        let counts = diceCounts(dice)
        if counts.values.contains(5) {
            return 50
        }
        return 0
    }

    /// Chance: Sum of all dice
    static func chance(dice: [Int]) -> Int {
        dice.reduce(0, +)
    }

    /// Validates that dice array contains exactly 5 dice with values 1-6
    static func isValidDice(_ dice: [Int]) -> Bool {
        dice.count == 5 && dice.allSatisfy { $0 >= 1 && $0 <= 6 }
    }

    /// Returns all potential scores for a given dice roll
    static func allPotentialScores(dice: [Int]) -> [ScoreCategory: Int] {
        guard isValidDice(dice) else { return [:] }

        return [
            .ones: ones(dice: dice),
            .twos: twos(dice: dice),
            .threes: threes(dice: dice),
            .fours: fours(dice: dice),
            .fives: fives(dice: dice),
            .sixes: sixes(dice: dice),
            .threeOfAKind: threeOfAKind(dice: dice),
            .fourOfAKind: fourOfAKind(dice: dice),
            .fullHouse: fullHouse(dice: dice),
            .smallStraight: smallStraight(dice: dice),
            .largeStraight: largeStraight(dice: dice),
            .yahtzee: yahtzee(dice: dice),
            .chance: chance(dice: dice)
        ]
    }
}

enum ScoreCategory: String, CaseIterable, Identifiable {
    // Upper Section
    case ones = "Ones"
    case twos = "Twos"
    case threes = "Threes"
    case fours = "Fours"
    case fives = "Fives"
    case sixes = "Sixes"

    // Lower Section
    case threeOfAKind = "Three of a Kind"
    case fourOfAKind = "Four of a Kind"
    case fullHouse = "Full House"
    case smallStraight = "Small Straight"
    case largeStraight = "Large Straight"
    case yahtzee = "Yahtzee"
    case chance = "Chance"

    var id: String { rawValue }

    var isUpperSection: Bool {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            return true
        default:
            return false
        }
    }

    static var upperSection: [ScoreCategory] {
        [.ones, .twos, .threes, .fours, .fives, .sixes]
    }

    static var lowerSection: [ScoreCategory] {
        [.threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .yahtzee, .chance]
    }

    var description: String {
        switch self {
        case .ones: return "Sum of all ones"
        case .twos: return "Sum of all twos"
        case .threes: return "Sum of all threes"
        case .fours: return "Sum of all fours"
        case .fives: return "Sum of all fives"
        case .sixes: return "Sum of all sixes"
        case .threeOfAKind: return "3 of same kind, sum all dice"
        case .fourOfAKind: return "4 of same kind, sum all dice"
        case .fullHouse: return "3 of one + 2 of another = 25"
        case .smallStraight: return "4 in a row = 30"
        case .largeStraight: return "5 in a row = 40"
        case .yahtzee: return "5 of a kind = 50"
        case .chance: return "Sum of all dice"
        }
    }
}
