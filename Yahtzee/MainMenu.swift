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

                    // High Scores button
                    Button {
                        showHighScores = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                            Text("High Scores")
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

        // Play appropriate sound
        if category == .yahtzee && score == 50 {
            SoundManager.shared.playYahtzee()
        } else {
            SoundManager.shared.playScore()
        }

        currentPlayer.scoreCard.score(category: category, value: score)
        nextTurn()
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
