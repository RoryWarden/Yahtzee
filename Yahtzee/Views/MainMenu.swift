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
    @State private var showSettings = false
    @State private var playerNames: [String] = [""]
    @State private var gameState: GameState?
    @Bindable var settings = SettingsManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.menuGradient
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
                        .foregroundColor(Theme.primaryDark)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(
                            Capsule()
                                .fill(Theme.menuButton)
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

                    Spacer()
                        .frame(height: 30)
                }

                // Settings button (bottom left)
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Theme.menuButtonSecondary)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(20)

                        Spacer()
                    }
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(item: $gameState) { state in
                PlayView(gameState: state)
            }
            .preferredColorScheme(settings.colorScheme)
            .id("\(settings.appTheme)-\(settings.selectedCustomThemeId?.uuidString ?? "")") // Force refresh when theme changes
            .onChange(of: settings.soundEnabled) { _, enabled in
                SoundManager.shared.isEnabled = enabled
            }
            .onAppear {
                // Sync sound setting on launch
                SoundManager.shared.isEnabled = settings.soundEnabled
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
                        ForEach(Array(highScores.enumerated()), id: \.element.id) { index, entry in
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
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 400)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
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
            .foregroundColor(.white.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.menuButtonSecondary)
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
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
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
    @State private var games: [GameRecord] = []
    @State private var selectedGame: GameRecord?

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
            .onAppear {
                games = GameHistoryManager.shared.recentGames(limit: 20)
            }

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
                            Button {
                                selectedGame = game
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Label("\(game.playerCount) players", systemImage: "person.2")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Button {
                                            withAnimation {
                                                // Delete matching high scores for each player
                                                for player in game.players {
                                                    HighScoreManager.shared.deleteScores(
                                                        playerName: player.playerName,
                                                        score: player.finalScore,
                                                        date: game.date
                                                    )
                                                }
                                                // Delete from history
                                                GameHistoryManager.shared.deleteGame(game)
                                                games.removeAll { $0.id == game.id }
                                                // Recalculate statistics from remaining history
                                                PlayerStatsManager.shared.recalculateFromHistory()
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
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
                                                .foregroundColor(.primary)

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
                                                .foregroundColor(.primary)
                                        }
                                    }

                                    HStack {
                                        Spacer()
                                        Text("Tap to view score cards")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(24)
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 450)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .sheet(item: $selectedGame) { game in
            GameDetailSheet(game: game)
        }
    }
}

struct GameDetailSheet: View {
    let game: GameRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Game Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(game.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(game.players.sorted(by: { $0.finalScore > $1.finalScore })) { player in
                        HistoryScoreCardView(player: player, isWinner: player.playerName == game.winnerName)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 550)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

struct HistoryScoreCardView: View {
    let player: PlayerGameRecord
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
                Text(player.playerName)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isWinner ? Theme.primary.opacity(0.2) : Color.gray.opacity(0.1))

            Divider()

            // Upper Section
            VStack(spacing: 0) {
                Text("UPPER")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)

                ForEach(ScoreCategory.upperSection) { category in
                    ScoreHistoryRow(
                        label: category.rawValue,
                        score: player.score(for: category)
                    )
                }

                ScoreHistoryRow(label: "Bonus", score: player.upperBonus, highlight: player.upperBonus > 0)
                ScoreHistoryRow(label: "Upper Total", score: player.upperScore + player.upperBonus, isBold: true)
            }

            Divider()
                .padding(.vertical, 4)

            // Lower Section
            VStack(spacing: 0) {
                Text("LOWER")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)

                ForEach(ScoreCategory.lowerSection) { category in
                    ScoreHistoryRow(
                        label: category.rawValue,
                        score: player.score(for: category)
                    )
                }

                if player.yahtzeeBonus > 0 {
                    ScoreHistoryRow(label: "Yahtzee Bonus", score: player.yahtzeeBonus, highlight: true)
                }

                ScoreHistoryRow(label: "Lower Total", score: player.lowerScore, isBold: true)
            }

            Divider()
                .padding(.vertical, 4)

            // Grand Total
            HStack {
                Text("GRAND TOTAL")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(player.finalScore)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Theme.primaryLight)
        }
        .frame(width: 180)
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(uiColor: .systemBackground))
        #endif
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ScoreHistoryRow: View {
    let label: String
    let score: Int?
    var highlight: Bool = false
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(isBold ? .semibold : .regular)
                .foregroundColor(highlight ? Theme.success : .primary)
                .lineLimit(1)

            Spacer()

            if let score = score {
                Text("\(score)")
                    .font(.caption)
                    .fontWeight(isBold ? .semibold : .regular)
                    .foregroundColor(highlight ? Theme.success : .primary)
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
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
                            .foregroundColor(Theme.primary)
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
                                .fill(canStart ? Theme.primary : Color.gray)
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
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 400)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

@Observable
class GameState: Hashable {
    let id = UUID()
    var players: [Player]
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
