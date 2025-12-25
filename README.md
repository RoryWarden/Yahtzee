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
- **Sound Effects** - Audio feedback for rolling, holding, scoring, and Yahtzee
- **High Scores** - Persistent leaderboard saved between sessions
- **Yahtzee Bonus** - Multiple Yahtzees earn 100-point bonuses

## How to Play

1. Launch the app and click **Play**
2. Enter player names (1-4 players)
3. Each turn:
   - Roll the dice (up to 3 rolls per turn)
   - Click dice to hold/unhold them between rolls
   - Select a scoring category to end your turn
4. Game ends when all players have filled all 13 categories
5. Highest total score wins

## Project Structure

```
Yahtzee/
├── YahtzeeApp.swift      # App entry point
├── MainMenu.swift        # Main menu, player setup, high scores
├── PlayView.swift        # Game screen layout, game over
├── DiceView.swift        # Dice visuals and controls
├── DiceLogic.swift       # Dice state, rolling, physics simulation
├── ScoreCardView.swift   # Score card UI and state
├── ScoreCardMath.swift   # Scoring calculations for all categories
├── SoundManager.swift    # System sound effects
└── HighScoreManager.swift # High score persistence
```

## Technical Notes

### Dice Physics
The dice rolling animation simulates real die geometry. A standard die has opposite faces that sum to 7 (1↔6, 2↔5, 3↔4). When rolling, a die can only tumble to one of its 4 adjacent faces—never staying on the same face or jumping to the opposite face. This creates realistic tumble sequences with natural probability distributions.

### State Management
Uses Swift's `@Observable` macro for reactive state management across `GameState`, `DiceState`, and `ScoreCardState`.

## License

MIT
