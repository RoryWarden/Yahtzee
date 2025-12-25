//
//  PlayView.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import SwiftUI

struct PlayView: View {
    @Bindable var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showAllScores = false
    @State private var showGameOverSheet = false

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Score Cards
            ScrollView {
                VStack(spacing: 16) {
                    // Player tabs / names at top
                    PlayerTabsView(gameState: gameState)

                    if showAllScores {
                        // Show all players' score cards
                        AllPlayersScoreView(gameState: gameState)
                    } else {
                        // Current player's score card
                        ScoreCardView(
                            state: gameState.currentPlayer.scoreCard
                        ) { category in
                            if gameState.diceState.hasRolled &&
                               !gameState.currentPlayer.scoreCard.isScored(category) {
                                gameState.scoreCurrentPlayer(category: category)
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(minWidth: 300, maxWidth: showAllScores ? .infinity : 400)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Right side - Dice Area
            VStack {
                Spacer()

                // Turn info
                VStack(spacing: 8) {
                    Text("\(gameState.categoriesRemaining) categories left")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("\(gameState.currentPlayer.name)'s Turn")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // Dice control with roll button
                DiceControlView(state: gameState.diceState)
                    .onChange(of: gameState.diceState.values) { _, newValues in
                        if gameState.diceState.hasRolled {
                            gameState.currentPlayer.scoreCard.updatePotentialScores(dice: newValues)
                        }
                    }

                Spacer()

                // Instructions
                if !gameState.diceState.hasRolled {
                    Text("Roll the dice to start your turn")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else if gameState.diceState.rollsRemaining > 0 {
                    Text("Select a category to score, or roll again")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text("Select a category to score")
                        .font(.callout)
                        .foregroundColor(.orange)
                }

                Spacer()

                // Toggle to show all scores
                Button {
                    withAnimation {
                        showAllScores.toggle()
                    }
                } label: {
                    Label(
                        showAllScores ? "Show Current Player" : "Show All Scores",
                        systemImage: showAllScores ? "person" : "person.3"
                    )
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
            .frame(minWidth: 400)
            .padding()
        }
        .navigationTitle("Yahtzee")
        .onChange(of: gameState.isGameOver) { _, isOver in
            if isOver {
                // Play game over sound
                SoundManager.shared.playGameOver()

                // Save high scores when game ends
                for player in gameState.players {
                    HighScoreManager.shared.saveScore(
                        playerName: player.name,
                        score: player.scoreCard.grandTotal
                    )
                }
                showGameOverSheet = true
            }
        }
        .sheet(isPresented: $showGameOverSheet) {
            GameOverView(gameState: gameState) {
                dismiss()
            }
        }
    }
}

struct PlayerTabsView: View {
    @Bindable var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Players")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(gameState.players) { player in
                    PlayerTab(
                        name: player.name,
                        score: player.scoreCard.grandTotal,
                        isCurrentPlayer: player.id == gameState.currentPlayerIndex
                    )
                }
            }
        }
    }
}

struct PlayerTab: View {
    let name: String
    let score: Int
    let isCurrentPlayer: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.headline)
                .lineLimit(1)
            Text("\(score)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentPlayer ? Color.blue : Color.gray.opacity(0.2))
        )
        .foregroundColor(isCurrentPlayer ? .white : .primary)
    }
}

struct AllPlayersScoreView: View {
    @Bindable var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALL SCORES")
                .font(.headline)
                .padding(.bottom, 4)

            // Header row with player names
            HStack(spacing: 0) {
                Text("Category")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 120, alignment: .leading)

                ForEach(gameState.players) { player in
                    Text(player.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 70)
                        .foregroundColor(player.id == gameState.currentPlayerIndex ? .blue : .primary)
                }
            }
            .padding(.horizontal, 8)

            Divider()

            // Upper section
            ForEach(ScoreCategory.upperSection) { category in
                scoreRow(category: category)
            }

            // Upper totals
            totalRow(label: "Upper Bonus") { player in
                player.scoreCard.upperBonus
            }
            totalRow(label: "Upper Total") { player in
                player.scoreCard.upperTotalWithBonus
            }

            Divider()

            // Lower section
            ForEach(ScoreCategory.lowerSection) { category in
                scoreRow(category: category)
            }

            // Yahtzee bonus
            totalRow(label: "Yahtzee Bonus") { player in
                player.scoreCard.yahtzeeBonus
            }

            Divider()

            // Grand total
            HStack(spacing: 0) {
                Text("GRAND TOTAL")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)

                ForEach(gameState.players) { player in
                    Text("\(player.scoreCard.grandTotal)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 70)
                        .foregroundColor(player.id == gameState.currentPlayerIndex ? .blue : .primary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func scoreRow(category: ScoreCategory) -> some View {
        HStack(spacing: 0) {
            Text(category.rawValue)
                .font(.caption)
                .frame(width: 120, alignment: .leading)

            ForEach(gameState.players) { player in
                if let score = player.scoreCard.scores[category] ?? nil {
                    Text("\(score)")
                        .font(.caption)
                        .frame(width: 70)
                } else {
                    Text("-")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    private func totalRow(label: String, value: @escaping (Player) -> Int) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            ForEach(gameState.players) { player in
                Text("\(value(player))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 70)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

struct GameOverView: View {
    let gameState: GameState
    let onDismiss: () -> Void

    private var sortedPlayers: [Player] {
        gameState.players.sorted { $0.scoreCard.grandTotal > $1.scoreCard.grandTotal }
    }

    private var winner: Player? {
        sortedPlayers.first
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let winner = winner {
                VStack(spacing: 8) {
                    Text("\(winner.name) Wins!")
                        .font(.title)
                        .foregroundColor(.green)

                    Text("\(winner.scoreCard.grandTotal) points")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Final standings
            VStack(alignment: .leading, spacing: 12) {
                Text("Final Standings")
                    .font(.headline)

                ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack {
                        Text("\(index + 1).")
                            .fontWeight(.semibold)
                            .frame(width: 30)

                        Text(player.name)

                        Spacer()

                        Text("\(player.scoreCard.grandTotal)")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Divider()

            // High scores
            VStack(alignment: .leading, spacing: 12) {
                Text("High Scores")
                    .font(.headline)

                let highScores = HighScoreManager.shared.topScores(limit: 5)
                if highScores.isEmpty {
                    Text("No high scores yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(highScores.enumerated()), id: \.offset) { index, entry in
                        HStack {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                                .frame(width: 30)

                            Text(entry.playerName)

                            Spacer()

                            Text("\(entry.score)")
                                .fontWeight(.semibold)

                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Button("Back to Menu") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding(32)
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    let state = GameState(playerNames: ["Kate", "Duplicate"])
    state.diceState.roll()

    return NavigationStack {
        PlayView(gameState: state)
    }
}
