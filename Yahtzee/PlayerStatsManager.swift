//
//  PlayerStatsManager.swift
//  Yahtzee
//
//  Tracks player statistics across games.
//

import Foundation

struct PlayerStats: Codable, Identifiable {
    var id: String { playerName }
    let playerName: String
    var gamesPlayed: Int
    var totalScore: Int
    var highScore: Int
    var totalYahtzees: Int
    var lastPlayed: Date

    var averageScore: Double {
        gamesPlayed > 0 ? Double(totalScore) / Double(gamesPlayed) : 0
    }
}

class PlayerStatsManager {
    static let shared = PlayerStatsManager()

    private let statsKey = "YahtzeePlayerStats"

    private init() {}

    private var allStats: [String: PlayerStats] {
        get {
            guard let data = UserDefaults.standard.data(forKey: statsKey),
                  let stats = try? JSONDecoder().decode([String: PlayerStats].self, from: data) else {
                return [:]
            }
            return stats
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: statsKey)
            }
        }
    }

    func recordGame(playerName: String, score: Int, yahtzeeCount: Int) {
        var stats = allStats

        if var existing = stats[playerName] {
            existing.gamesPlayed += 1
            existing.totalScore += score
            existing.highScore = max(existing.highScore, score)
            existing.totalYahtzees += yahtzeeCount
            existing.lastPlayed = Date()
            stats[playerName] = existing
        } else {
            stats[playerName] = PlayerStats(
                playerName: playerName,
                gamesPlayed: 1,
                totalScore: score,
                highScore: score,
                totalYahtzees: yahtzeeCount,
                lastPlayed: Date()
            )
        }

        allStats = stats
    }

    func stats(for playerName: String) -> PlayerStats? {
        allStats[playerName]
    }

    func allPlayerStats() -> [PlayerStats] {
        Array(allStats.values).sorted { $0.highScore > $1.highScore }
    }

    func topPlayers(limit: Int = 10) -> [PlayerStats] {
        Array(allPlayerStats().prefix(limit))
    }

    func clearStats() {
        allStats = [:]
    }
}
