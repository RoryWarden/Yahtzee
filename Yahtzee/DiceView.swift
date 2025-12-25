//
//  DiceView.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import SwiftUI

struct DiceRowView: View {
    @Bindable var state: DiceState

    var body: some View {
        HStack(spacing: 12) {
            ForEach(state.dice) { die in
                SingleDieView(
                    value: die.value,
                    isHeld: die.isHeld,
                    isRolling: die.isRolling,
                    canHold: state.hasRolled && !state.isRolling
                ) {
                    state.toggleHold(at: die.id)
                }
            }
        }
        .padding()
    }
}

struct SingleDieView: View {
    let value: Int
    let isHeld: Bool
    let isRolling: Bool
    let canHold: Bool
    let onTap: () -> Void

    @State private var bounceOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0

    private let dieSize: CGFloat = 60
    private let dotSize: CGFloat = 10
    private let cornerRadius: CGFloat = 10

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Held indicator border
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .fill(isHeld ? Color.orange : Color.clear)
                    .frame(width: dieSize + 8, height: dieSize + 8)

                // Die background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: dieSize, height: dieSize)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)

                // Die border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(width: dieSize, height: dieSize)

                // Dots - animate the value changes
                DieFaceView(value: value, dotSize: dotSize)
                    .frame(width: dieSize - 16, height: dieSize - 16)
                    .id(value) // Force view recreation on value change
                    .transition(.scale.combined(with: .opacity))
            }
            .offset(y: bounceOffset)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.3
            )
            .animation(.easeInOut(duration: 0.05), value: value)
        }
        .buttonStyle(.plain)
        .disabled(!canHold)
        .opacity(canHold ? 1.0 : 0.7)
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                startRollingAnimation()
            } else {
                settleAnimation()
            }
        }
    }

    private func startRollingAnimation() {
        // Continuous subtle bounce while rolling
        withAnimation(
            .easeInOut(duration: 0.15)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -3
            rotationAngle = 8
        }
    }

    private func settleAnimation() {
        // Settle back to rest
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bounceOffset = 0
            rotationAngle = 0
        }
    }
}

struct DieFaceView: View {
    let value: Int
    let dotSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let positions = dotPositions(for: value, in: size)

            ZStack {
                ForEach(0..<positions.count, id: \.self) { index in
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(positions[index])
                }
            }
        }
    }

    private func dotPositions(for value: Int, in size: CGFloat) -> [CGPoint] {
        let padding: CGFloat = size * 0.15
        let left = padding
        let center = size / 2
        let right = size - padding
        let top = padding
        let middle = size / 2
        let bottom = size - padding

        switch value {
        case 1:
            return [CGPoint(x: center, y: middle)]
        case 2:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: bottom)
            ]
        case 3:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: center, y: middle),
                CGPoint(x: right, y: bottom)
            ]
        case 4:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom)
            ]
        case 5:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: center, y: middle),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom)
            ]
        case 6:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: middle),
                CGPoint(x: right, y: middle),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom)
            ]
        default:
            return []
        }
    }
}

struct RollButton: View {
    let rollsRemaining: Int
    let canRoll: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .font(.title2)
                Text(rollsRemaining == 3 ? "Roll Dice" : "Roll (\(rollsRemaining) left)")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canRoll ? Color.blue : Color.gray)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(!canRoll)
    }
}

struct DiceControlView: View {
    @Bindable var state: DiceState

    var body: some View {
        VStack(spacing: 16) {
            DiceRowView(state: state)

            HStack(spacing: 12) {
                if state.hasRolled {
                    Button("Hold All") {
                        state.holdAll()
                    }
                    .buttonStyle(.bordered)

                    Button("Release All") {
                        state.releaseAll()
                    }
                    .buttonStyle(.bordered)
                }

                RollButton(
                    rollsRemaining: state.rollsRemaining,
                    canRoll: state.canRoll,
                    action: { state.roll() }
                )
            }

            if state.hasRolled {
                Text("Tap dice to hold/release")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.15))
        )
    }
}

#Preview("Dice Control") {
    let state = DiceState()
    state.roll()
    state.dice[0].isHeld = true
    state.dice[2].isHeld = true

    return DiceControlView(state: state)
        .padding()
}

#Preview("Single Die") {
    HStack(spacing: 20) {
        ForEach(1...6, id: \.self) { value in
            SingleDieView(value: value, isHeld: value == 3, isRolling: false, canHold: true) { }
        }
    }
    .padding()
}
