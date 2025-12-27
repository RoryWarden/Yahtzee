//
//  DiceLogic.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//
//  Manages the state of all 5 dice in a Yahtzee game.
//  Handles rolling, holding, and the animated tumble sequence.
//

import Foundation

@Observable
class DiceState {
    /// The 5 dice used in Yahtzee
    var dice: [Die] = (0..<5).map { Die(id: $0) }

    /// Players get 3 rolls per turn
    var rollsRemaining: Int = 3

    /// Has the player rolled at least once this turn?
    var hasRolled: Bool = false

    /// Are any dice currently animating?
    var isRolling: Bool = false

    /// Convenience: get all current die values as an array for scoring
    var values: [Int] {
        dice.map { $0.value }
    }

    /// Check if all dice are held (can't roll if nothing to roll)
    var allHeld: Bool {
        dice.allSatisfy { $0.isHeld }
    }

    /// Can the player roll? Need rolls left, at least one unheld die, and not mid-animation
    var canRoll: Bool {
        rollsRemaining > 0 && !allHeld && !isRolling
    }

    /// Roll all unheld dice with animated tumbling
    func roll() {
        guard canRoll else { return }

        isRolling = true
        rollsRemaining -= 1
        hasRolled = true

        // Play dice rolling sound effect
        SoundManager.shared.playDiceRoll()

        // Each unheld die gets its own tumble sequence
        // This creates natural variation - dice don't all land at the same time
        for i in dice.indices {
            if !dice[i].isHeld {
                dice[i].isRolling = true
                // Generate the sequence of faces the die will show as it tumbles
                let sequence = DicePhysics.tumbleSequence(from: dice[i].value)
                animateDieTumble(dieIndex: i, sequence: sequence)
            }
        }
    }

    /// Animate a single die through its tumble sequence
    /// Each frame is scheduled with increasing delays (starts fast, slows down)
    private func animateDieTumble(dieIndex: Int, sequence: [Int]) {
        // Get timing for each frame - early frames are quick, later frames slower
        let timings = DicePhysics.tumbleTimings(frameCount: sequence.count)
        var cumulativeDelay: Double = 0

        for (frameIndex, value) in sequence.enumerated() {
            let delay = cumulativeDelay
            cumulativeDelay += timings[frameIndex]

            // Schedule each frame update
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                dice[dieIndex].value = value

                // Mark this die as finished on the last frame
                if frameIndex == sequence.count - 1 {
                    dice[dieIndex].isRolling = false
                    checkAllDiceFinished()
                }
            }
        }
    }

    /// When all dice finish animating, mark the overall roll as complete
    private func checkAllDiceFinished() {
        if dice.allSatisfy({ !$0.isRolling }) {
            isRolling = false
        }
    }

    /// Toggle hold state on a die (only allowed after first roll)
    func toggleHold(at index: Int) {
        guard hasRolled else { return }
        guard dice.indices.contains(index) else { return }
        dice[index].isHeld.toggle()
        SoundManager.shared.playHold()
    }

    /// Reset for a new turn - release all holds but keep dice values visible
    func reset() {
        for i in dice.indices {
            dice[i].isHeld = false
            // Note: We keep dice values as-is (don't reset to 1)
            // This looks more natural between turns
        }
        rollsRemaining = 3
        hasRolled = false
    }

    func holdAll() {
        for i in dice.indices {
            dice[i].isHeld = true
        }
    }

    func releaseAll() {
        for i in dice.indices {
            dice[i].isHeld = false
        }
    }
	
    #if DEBUG
    /// Debug: Force all dice to show the same value (instant Yahtzee)
    func forceYahtzee(value: Int = 0) {
        let yahtzeeValue = value == 0 ? Int.random(in: 1...6) : value
        for i in dice.indices {
            dice[i].value = yahtzeeValue
            dice[i].isHeld = false
        }
        rollsRemaining = 0
        hasRolled = true
        isRolling = false
    }
    #endif
}

struct Die: Identifiable {
    let id: Int
    var value: Int = Int.random(in: 1...6)  // Random starting value
    var isHeld: Bool = false
    var isRolling: Bool = false
}

// Simulates realistic dice tumbling based on the physical geometry of a standard die.
//
// KEY INSIGHT: On a real die, you can't roll from one face directly to any other face.
// A die can only tumble to an ADJACENT face - one of the 4 faces touching the current top face.
//
// STANDARD DIE LAYOUT:
// - Opposite faces always sum to 7: (1↔6), (2↔5), (3↔4)
// - This means if 1 is on top, 6 is on bottom (unreachable in one tumble)
// - The 4 adjacent faces to 1 are: 2, 3, 4, 5
//
// TUMBLE SIMULATION:
// When a die rolls, it tumbles through a sequence of adjacent faces.
// Example: Starting at 1 → could go to 3 → then to 6 → then to 4 → then to 1...
//
// This creates more realistic probability distributions than pure random:
// - Can't roll the same number twice in a row (must tumble away first)
// - Can't jump directly to the opposite face
// - The path through faces follows physical constraints

struct DicePhysics {

    /// On a standard die, opposite faces sum to 7
    /// If showing 1, bottom is 6. If showing 2, bottom is 5. Etc.
    static func oppositeFace(of value: Int) -> Int {
        7 - value
    }

    /// Returns the 4 faces adjacent to the current top face
    /// These are the only faces a die can tumble to in one rotation
    ///
    /// Example: If showing 1 (with 6 on bottom):
    /// - Adjacent faces are 2, 3, 4, 5
    /// - Can't stay on 1 (no tumble) or go to 6 (opposite/bottom)
    static func adjacentFaces(of value: Int) -> [Int] {
        let opposite = oppositeFace(of: value)
        return [1, 2, 3, 4, 5, 6].filter { $0 != value && $0 != opposite }
    }

    /// Simple tumble - just returns the final value
    static func tumble(from startValue: Int) -> Int {
        return tumbleSequence(from: startValue).last ?? startValue
    }

    /// Generates the full sequence of faces shown as the die tumbles
    ///
    /// The die makes 22-28 tumbles (randomly varied per roll)
    /// Each tumble picks randomly from the 4 adjacent faces
    /// This creates a realistic "bouncing" path through die faces
    ///
    /// Example sequence from starting value 3:
    /// 3 → 1 → 5 → 3 → 2 → 6 → 4 → 1 → 2 → 3 → 5 → 6 → 2 → ... → final value
    static func tumbleSequence(from startValue: Int) -> [Int] {
        var sequence: [Int] = []
        var currentFace = startValue

        // 22-28 frames fills ~2.5 seconds nicely with our easing curve
        let tumbleCount = Int.random(in: 22...28)

        for _ in 0..<tumbleCount {
            let adjacent = adjacentFaces(of: currentFace)
            currentFace = adjacent.randomElement() ?? currentFace
            sequence.append(currentFace)
        }

        return sequence
    }

    /// Calculates timing intervals for each frame of the tumble animation
    ///
    /// Creates a "slowing down" effect like a real die coming to rest:
    /// - Early frames: ~50ms each (fast tumbling, 20 changes/sec)
    /// - Late frames: ~200ms each (slowing down, settling)
    ///
    /// Uses quadratic easing: weight = 1 + progress² × 3
    /// This makes intervals grow slowly at first, then faster at the end
    ///
    /// Total duration is normalized to exactly 2.5 seconds regardless of frame count
    static func tumbleTimings(frameCount: Int) -> [Double] {
        let totalDuration: Double = 2.5
        var timings: [Double] = []

        // Generate weights that increase over time (later frames take longer)
        var weights: [Double] = []
        for i in 0..<frameCount {
            let progress = Double(i) / Double(max(frameCount - 1, 1))
            // Quadratic ease-out curve: starts at weight 1.0, ends at weight 4.0
            let weight = 1.0 + progress * progress * 3.0
            weights.append(weight)
        }

        // Normalize so all weights sum to totalDuration
        // This guarantees the animation takes exactly 2.5 seconds
        let totalWeight = weights.reduce(0, +)
        for weight in weights {
            timings.append(weight / totalWeight * totalDuration)
        }

        return timings
    }
}
