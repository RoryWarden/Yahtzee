//
//  GameHistoryManager.swift
//  Yahtzee
//
//  Stores complete game history with all player scores.
//

import Foundation

struct GameRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let players: [PlayerGameRecord]
    let winnerName: String

    var playerCount: Int { players.count }
}

struct PlayerGameRecord: Codable, Identifiable {
    var id: String { playerName }
    let playerName: String
    let finalScore: Int
    let upperScore: Int
    let lowerScore: Int
    let upperBonus: Int
    let yahtzeeBonus: Int
    let hadYahtzee: Bool
}

class GameHistoryManager {
    static let shared = GameHistoryManager()

    private let historyKey = "YahtzeeGameHistory"
    private let maxGames = 100 // Keep last 100 games

    private init() {}

    private var games: [GameRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: historyKey),
                  let history = try? JSONDecoder().decode([GameRecord].self, from: data) else {
                return []
            }
            return history
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: historyKey)
            }
        }
    }

    func saveGame(gameState: GameState) {
        let playerRecords = gameState.players.map { player in
            PlayerGameRecord(
                playerName: player.name,
                finalScore: player.scoreCard.grandTotal,
                upperScore: player.scoreCard.upperSectionTotal,
                lowerScore: player.scoreCard.lowerSectionTotal,
                upperBonus: player.scoreCard.upperBonus,
                yahtzeeBonus: player.scoreCard.yahtzeeBonus,
                hadYahtzee: player.scoreCard.scores[.yahtzee] == 50
            )
        }

        let winner = playerRecords.max(by: { $0.finalScore < $1.finalScore })?.playerName ?? ""

        let record = GameRecord(
            id: UUID(),
            date: Date(),
            players: playerRecords,
            winnerName: winner
        )

        var history = games
        history.insert(record, at: 0)

        // Keep only the last maxGames
        if history.count > maxGames {
            history = Array(history.prefix(maxGames))
        }

        games = history
    }

    func recentGames(limit: Int = 20) -> [GameRecord] {
        Array(games.prefix(limit))
    }

    func allGames() -> [GameRecord] {
        games
    }

    func gamesForPlayer(_ playerName: String) -> [GameRecord] {
        games.filter { game in
            game.players.contains { $0.playerName == playerName }
        }
    }

    func clearHistory() {
        games = []
    }
}
