# Yahtzee

A native macOS Yahtzee game built with SwiftUI.

## Requirements

- macOS 14.0+
- Xcode 15.0+

## Features

- **1-4 Players** - Local multiplayer with turn-based gameplay
- **Complete Scoring** - All 13 Yahtzee categories with automatic score calculation
- **Realistic Dice Physics** - Dice tumble through adjacent faces based on real die geometry (opposite faces sum to 7)
- **Visual Dice** - Animated rolling with dot patterns and hold indicators
- **Sound Effects** - Audio feedback for rolling, holding, scoring, and Yahtzee (toggleable)
- **Yahtzee Celebration** - Confetti animation when you roll a Yahtzee
- **Yahtzee Bonus** - Multiple Yahtzees earn 100-point bonuses
- **Upper Bonus Tracker** - Visual progress bar showing points toward the 63-point bonus
- **Undo** - Accidentally scored wrong? Undo your last move
- **High Scores** - Persistent leaderboard saved between sessions
- **Player Statistics** - Track games played, average scores, and total Yahtzees per player
- **Game History** - Browse past games with full score breakdowns
- **Dark Mode** - Automatic support for macOS light and dark themes

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Roll dice |
| `1-5` | Toggle hold on dice 1-5 |
| `Cmd+Z` | Undo last score |
| `Enter` | Start game (in player setup) |

## How to Play

1. Launch the app and click **Play**
2. Enter player names (1-4 players)
3. Each turn:
   - Roll the dice (up to 3 rolls per turn)
   - Click dice or press 1-5 to hold/unhold them between rolls
   - Select a scoring category to end your turn
4. Game ends when all players have filled all 13 categories
5. Highest total score wins

## Project Structure

```
Yahtzee/
├── YahtzeeApp.swift        # App entry point
├── MainMenu.swift          # Main menu, player setup, high scores
├── PlayView.swift          # Game screen layout, game over, celebration
├── DiceView.swift          # Dice visuals and controls
├── DiceLogic.swift         # Dice state, rolling, physics simulation
├── ScoreCardView.swift     # Score card UI, state, bonus progress
├── ScoreCardMath.swift     # Scoring calculations for all categories
├── SoundManager.swift      # System sound effects
├── HighScoreManager.swift  # High score persistence
├── PlayerStatsManager.swift # Player statistics tracking
└── GameHistoryManager.swift # Game history storage
```

## Technical Notes

### Dice Physics
The dice rolling animation simulates real die geometry. A standard die has opposite faces that sum to 7 (1↔6, 2↔5, 3↔4). When rolling, a die can only tumble to one of its 4 adjacent faces—never staying on the same face or jumping to the opposite face. This creates realistic tumble sequences with natural probability distributions.

### State Management
Uses Swift's `@Observable` macro for reactive state management across `GameState`, `DiceState`, and `ScoreCardState`.

### Persistence
High scores, player statistics, and game history are stored in UserDefaults for persistence between sessions.

## License

MIT
