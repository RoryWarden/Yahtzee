//
//  SoundManager.swift
//  Yahtzee
//
//  Created by Claude on 12/25/25.
//

import AVFoundation
import AppKit

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [AVAudioPlayer] = []
    private var diceRollTimer: Timer?

    private init() {}

    /// Play dice rolling sound - rapid clicking that slows down
    func playDiceRoll() {
        // Cancel any existing roll sound
        diceRollTimer?.invalidate()

        var delay: Double = 0
        var interval: Double = 0.05  // Start fast
        let totalDuration: Double = 2.5
        var elapsed: Double = 0

        // Schedule a series of click sounds that slow down
        while elapsed < totalDuration {
            let capturedDelay = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + capturedDelay) { [weak self] in
                self?.playClick()
            }

            elapsed += interval
            delay += interval

            // Slow down over time (quadratic easing)
            let progress = elapsed / totalDuration
            interval = 0.05 + progress * progress * 0.2
        }

        // Final "landing" sound
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.playLand()
        }
    }

    /// Play a single click sound (die hitting table)
    func playClick() {
        NSSound(named: "Tink")?.play()
    }

    /// Play landing/settling sound
    func playLand() {
        NSSound(named: "Pop")?.play()
    }

    /// Play sound when holding a die
    func playHold() {
        NSSound(named: "Morse")?.play()
    }

    /// Play sound when scoring
    func playScore() {
        NSSound(named: "Glass")?.play()
    }

    /// Play sound for Yahtzee!
    func playYahtzee() {
        NSSound(named: "Funk")?.play()
    }

    /// Play sound for game over
    func playGameOver() {
        NSSound(named: "Hero")?.play()
    }
}
