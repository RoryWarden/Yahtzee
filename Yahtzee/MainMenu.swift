//
//  MainMenu.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import SwiftUI

struct MainMenu: View {
    @State private var showPlayerSetup = false
    @State private var showHighScores = false
    @State private var showStats = false
    @State private var showHistory = false
    @State private var playerNames: [String] = [""]
    @State private var gameState: GameState?
    @State private var soundEnabled = SoundManager.shared.isEnabled

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Title
                    VStack(spacing: 8) {
                        Text("YAHTZEE")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)

                        // Decorative dice
                        HStack(spacing: 12) {
                            ForEach([5, 3, 6, 2, 4], id: \.self) { value in
                                MiniDieView(value: value)
                            }
                        }
                    }

                    Spacer()

                    // Play Button
                    Button {
                        showPlayerSetup = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title)
                            Text("PLAY")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Menu buttons row
                    HStack(spacing: 12) {
                        // High Scores button
                        MenuButton(icon: "trophy.fill", text: "High Scores") {
                            showHighScores = true
                        }

                        // Stats button
                        MenuButton(icon: "chart.bar.fill", text: "Statistics") {
                            showStats = true
                        }

                        // History button
                        MenuButton(icon: "clock.fill", text: "History") {
                            showHistory = true
                        }
                    }

                    // Sound toggle
                    Button {
                        soundEnabled.toggle()
                        SoundManager.shared.isEnabled = soundEnabled
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            Text(soundEnabled ? "Sound On" : "Sound Off")
                        }
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showPlayerSetup) {
                PlayerSetupView(
                    playerNames: $playerNames,
                    onStart: { names in
                        gameState = GameState(playerNames: names)
                        showPlayerSetup = false
                    }
                )
            }
            .sheet(isPresented: $showHighScores) {
                HighScoresSheet()
            }
            .sheet(isPresented: $showStats) {
                PlayerStatsSheet()
            }
            .sheet(isPresented: $showHistory) {
                GameHistorySheet()
            }
            .navigationDestination(item: $gameState) { state in
                PlayView(gameState: state)
            }
        }
    }
}

struct HighScoresSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("High Scores")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            let highScores = HighScoreManager.shared.topScores(limit: 10)

            if highScores.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No high scores yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Play a game to set your first score!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(highScores.enumerated()), id: \.offset) { index, entry in
                            HStack {
                                Text("\(index + 1).")
                                    .fontWeight(.semibold)
                                    .foregroundColor(index < 3 ? .orange : .primary)
                                    .frame(width: 30, alignment: .leading)

                                if index == 0 {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                }

                                Text(entry.playerName)
                                    .fontWeight(index < 3 ? .semibold : .regular)

                                Spacer()

                                Text("\(entry.score)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(index < 3 ? .orange : .primary)

                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(index % 2 == 0 ? Color.gray.opacity(0.05) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 450, minHeight: 400)
    }
}

struct MenuButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlayerStatsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Player Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
				Button("Done") {
					dismiss()
				}
				.buttonStyle(.bordered)
            }

            let stats = PlayerStatsManager.shared.allPlayerStats()

            if stats.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No statistics yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Complete a game to start tracking stats!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(stats) { stat in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(stat.playerName)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(stat.gamesPlayed) games")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 24) {
                                    StatItem(label: "High Score", value: "\(stat.highScore)")
                                    StatItem(label: "Average", value: String(format: "%.0f", stat.averageScore))
                                    StatItem(label: "Yahtzees", value: "\(stat.totalYahtzees)")
                                }

                                Text("Last played: \(stat.lastPlayed.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct GameHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Game History")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            let games = GameHistoryManager.shared.recentGames(limit: 20)

            if games.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No games yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Your game history will appear here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(games) { game in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Label("\(game.playerCount) players", systemImage: "person.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                ForEach(game.players.sorted(by: { $0.finalScore > $1.finalScore })) { player in
                                    HStack {
                                        if player.playerName == game.winnerName {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }

                                        Text(player.playerName)
                                            .fontWeight(player.playerName == game.winnerName ? .semibold : .regular)

                                        Spacer()

                                        if player.hadYahtzee {
                                            Text("YAHTZEE")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }

                                        Text("\(player.finalScore)")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 450)
    }
}

struct MiniDieView: View {
    let value: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)

            DieFaceView(value: value, dotSize: 6)
                .frame(width: 24, height: 24)
        }
    }
}

struct PlayerNameEntry: Identifiable {
    let id = UUID()
    var name: String = ""
}

struct PlayerSetupView: View {
    @Binding var playerNames: [String]
    let onStart: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [PlayerNameEntry] = [PlayerNameEntry()]

    private var validNames: [String] {
        entries.map { $0.name.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var canStart: Bool { !validNames.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter Player Names")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                Text("Add 1-4 players")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            TextField("Player \(index + 1)", text: $entries[index].name)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    if canStart {
                                        onStart(validNames)
                                    }
                                }

                            if entries.count > 1 {
                                Button {
                                    entries.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                if entries.count < 4 {
                    Button {
                        entries.append(PlayerNameEntry())
                    } label: {
                        Label("Add Player", systemImage: "plus.circle.fill")
                    }
                }

                Spacer()

                Button {
                    onStart(validNames)
                } label: {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(canStart ? Color.green : Color.gray)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!canStart)
                .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 350, minHeight: 400)
    }
}

@Observable
class GameState: Hashable {
    let id = UUID()
    let players: [Player]
    var currentPlayerIndex: Int = 0
    var diceState: DiceState = DiceState()

    // Undo support
    private var lastScoredPlayerIndex: Int?
    private var lastScoredCategory: ScoreCategory?
    private var lastScoredValue: Int?
    private var lastYahtzeeBonusCount: Int?
    var canUndo: Bool { lastScoredCategory != nil }

    // Yahtzee celebration callback
    var onYahtzee: (() -> Void)?

    init(playerNames: [String]) {
        self.players = playerNames.enumerated().map { index, name in
            Player(id: index, name: name)
        }
    }

    static func == (lhs: GameState, rhs: GameState) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    var isGameOver: Bool {
        players.allSatisfy { $0.scoreCard.isComplete }
    }

    var categoriesRemaining: Int {
        ScoreCategory.allCases.count - currentPlayer.scoreCard.scores.values.compactMap { $0 }.count
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        diceState.reset()
    }

    func scoreCurrentPlayer(category: ScoreCategory) {
        guard let score = currentPlayer.scoreCard.potentialScores[category] else { return }

        // Save undo state before scoring
        lastScoredPlayerIndex = currentPlayerIndex
        lastScoredCategory = category
        lastScoredValue = score
        lastYahtzeeBonusCount = currentPlayer.scoreCard.yahtzeeBonusCount

        // Play appropriate sound and trigger celebration
        if category == .yahtzee && score == 50 {
            SoundManager.shared.playYahtzee()
            onYahtzee?()
        } else {
            SoundManager.shared.playScore()
        }

        currentPlayer.scoreCard.score(category: category, value: score)
        nextTurn()
    }

    func undoLastScore() {
        guard let playerIndex = lastScoredPlayerIndex,
              let category = lastScoredCategory else { return }

        // Go back to the player who scored
        currentPlayerIndex = playerIndex

        // Remove the score
        players[playerIndex].scoreCard.unscore(category: category)

        // Restore yahtzee bonus count if needed
        if let bonusCount = lastYahtzeeBonusCount {
            players[playerIndex].scoreCard.yahtzeeBonusCount = bonusCount
        }

        // Clear undo state (can only undo once)
        lastScoredPlayerIndex = nil
        lastScoredCategory = nil
        lastScoredValue = nil
        lastYahtzeeBonusCount = nil

        // Restore dice state for re-scoring
        diceState.rollsRemaining = 0
        diceState.hasRolled = true
    }
}

struct Player: Identifiable {
    let id: Int
    let name: String
    var scoreCard: ScoreCardState = ScoreCardState()
}

#Preview {
    MainMenu()
}
