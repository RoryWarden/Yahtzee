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
    @State private var showYahtzeeCelebration = false

    var body: some View {
        ZStack {
        HStack(spacing: 0) {
            // Left side - Score Card
            ScrollView {
                if showAllScores {
                    // Show all players' score cards
                    AllPlayersScoreView(gameState: gameState)
                        .padding()
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
            .frame(minWidth: 320, maxWidth: showAllScores ? .infinity : 380)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Right side - Dice Area
            VStack(spacing: 16) {
                // Player tabs at top
                PlayerTabsView(gameState: gameState)
                    .padding(.top, 8)

                Spacer()

                // Turn info
                VStack(spacing: 4) {
                    Text("\(gameState.categoriesRemaining) categories left")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(gameState.currentPlayer.name)'s Turn")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                // Dice control with roll button
                DiceControlView(state: gameState.diceState)
                    .onChange(of: gameState.diceState.values) { _, newValues in
                        if gameState.diceState.hasRolled {
                            gameState.currentPlayer.scoreCard.updatePotentialScores(dice: newValues)
                        }
                    }

                // Instructions
                if !gameState.diceState.hasRolled {
                    Text("Roll the dice to start your turn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if gameState.diceState.rollsRemaining > 0 {
                    Text("Select a category to score, or roll again")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Select a category to score")
                        .font(.caption)
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
            .frame(minWidth: 450)
            .padding()
        }

            // Yahtzee celebration overlay
            if showYahtzeeCelebration {
                YahtzeeCelebrationView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showYahtzeeCelebration = false
                            }
                        }
                    }
            }
        } // end ZStack
        .frame(minWidth: 900, minHeight: 750)
        .navigationTitle("Yahtzee")
        .onAppear {
            gameState.onYahtzee = {
                withAnimation {
                    showYahtzeeCelebration = true
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    undoLastScore()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!gameState.canUndo)
                .keyboardShortcut("z", modifiers: .command)
            }
        }
        .onChange(of: gameState.isGameOver) { _, isOver in
            if isOver {
                // Play game over sound
                SoundManager.shared.playGameOver()

                // Save high scores and statistics when game ends
                for player in gameState.players {
                    HighScoreManager.shared.saveScore(
                        playerName: player.name,
                        score: player.scoreCard.grandTotal
                    )
                    PlayerStatsManager.shared.recordGame(
                        playerName: player.name,
                        score: player.scoreCard.grandTotal,
                        yahtzeeCount: player.scoreCard.scores[.yahtzee] == 50 ? 1 + player.scoreCard.yahtzeeBonusCount : 0
                    )
                }
                GameHistoryManager.shared.saveGame(gameState: gameState)
                showGameOverSheet = true
            }
        }
        .sheet(isPresented: $showGameOverSheet) {
            GameOverView(gameState: gameState) {
                dismiss()
            }
        }
        // Keyboard shortcuts for dice (1-5) and roll (space)
        .onKeyPress(.init("1")) { toggleDie(0); return .handled }
        .onKeyPress(.init("2")) { toggleDie(1); return .handled }
        .onKeyPress(.init("3")) { toggleDie(2); return .handled }
        .onKeyPress(.init("4")) { toggleDie(3); return .handled }
        .onKeyPress(.init("5")) { toggleDie(4); return .handled }
        .onKeyPress(.space) { rollDice(); return .handled }
    }

    private func toggleDie(_ index: Int) {
        guard gameState.diceState.hasRolled && !gameState.diceState.isRolling else { return }
        gameState.diceState.toggleHold(at: index)
    }

    private func rollDice() {
        guard gameState.diceState.canRoll else { return }
        gameState.diceState.roll()
    }

    private func undoLastScore() {
        gameState.undoLastScore()
    }
}

struct YahtzeeCelebrationView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("YAHTZEE!")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
                    .shadow(color: .red, radius: 20)

                Text("50 Points!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .scaleEffect(particles.isEmpty ? 0.5 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: particles.isEmpty)

            // Confetti particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }

    private func createConfetti() {
        let colors: [Color] = [.red, .yellow, .green, .blue, .orange, .purple, .pink]
        var newParticles: [ConfettiParticle] = []

        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(x: CGFloat.random(in: 0...800), y: -20),
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles

        // Animate particles falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...2.5)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    particles[i].position.y = 800
                    particles[i].position.x += CGFloat.random(in: -100...100)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration - 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
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
