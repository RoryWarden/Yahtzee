//
//  SoundManager.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import AVFoundation
import AudioToolbox

#if os(macOS)
import AppKit
#endif

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [AVAudioPlayer] = []
    private var diceRollTimer: Timer?

    private let soundEnabledKey = "YahtzeeSoundEnabled"

    /// Whether sounds are enabled (persisted to UserDefaults)
    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: soundEnabledKey) }
    }

    private init() {}

    /// Play dice rolling sound - rapid clicking that slows down
    func playDiceRoll() {
        guard isEnabled else { return }

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
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Tink")?.play()
        #else
        AudioServicesPlaySystemSound(1104)  // Keyboard tap
        #endif
    }

    /// Play landing/settling sound
    func playLand() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Pop")?.play()
        #else
        AudioServicesPlaySystemSound(1100)  // System sound
        #endif
    }

    /// Play sound when holding a die
    func playHold() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Morse")?.play()
        #else
        AudioServicesPlaySystemSound(1306)  // Key pressed
        #endif
    }

    /// Play sound when scoring
    func playScore() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Glass")?.play()
        #else
        AudioServicesPlaySystemSound(1057)  // SMS received
        #endif
    }

    /// Play sound for Yahtzee!
    func playYahtzee() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Funk")?.play()
        #else
        AudioServicesPlaySystemSound(1025)  // Fanfare
        #endif
    }

    /// Play sound for game over
    func playGameOver() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound(named: "Hero")?.play()
        #else
        AudioServicesPlaySystemSound(1320)  // Anticipate
        #endif
    }
}
