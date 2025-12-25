//
//  HighScoreManager.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import Foundation

struct HighScoreEntry: Codable, Identifiable {
    var id = UUID()
    let playerName: String
    let score: Int
    let date: Date
}

class HighScoreManager {
    static let shared = HighScoreManager()

    private let userDefaultsKey = "YahtzeeHighScores"
    private var scores: [HighScoreEntry] = []

    private init() { loadScores() }

    private func loadScores() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([HighScoreEntry].self, from: data) else {
            scores = []
            return
        }
        scores = decoded
    }

    private func saveScoresToDisk() {
        guard let data = try? JSONEncoder().encode(scores) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    func saveScore(playerName: String, score: Int) {
        let entry = HighScoreEntry(
            playerName: playerName,
            score: score,
            date: Date()
        )
        scores.append(entry)
        scores.sort { $0.score > $1.score }

        // Keep only top 100 scores
        if scores.count > 100 {
            scores = Array(scores.prefix(100))
        }

        saveScoresToDisk()
    }

    func topScores(limit: Int = 10) -> [HighScoreEntry] { Array(scores.prefix(limit)) }

	func scoresForPlayer(name: String) -> [HighScoreEntry] {
		scores.filter {
			$0.playerName.lowercased() == name.lowercased()
		}
	}

    func bestScoreForPlayer(name: String) -> HighScoreEntry? { scoresForPlayer(name: name).first }

    func clearAllScores() {
        scores = []
        saveScoresToDisk()
    }
}
