//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI
import WireDesign

struct InactivityTimerOverlayView: View {
    let onTap: () -> Void
    let onExpired: () -> Void

    @State private var secondsRemaining: Int
    private let totalSeconds: Int
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(initialSeconds: Int, onTap: @escaping () -> Void, onExpired: @escaping () -> Void) {
        self.totalSeconds = initialSeconds
        self._secondsRemaining = State(initialValue: initialSeconds)
        self.onTap = onTap
        self.onExpired = onExpired
    }

    var body: some View {
        ZStack {
            ColorTheme.Backgrounds.surface.color
                .opacity(0.97)
                .ignoresSafeArea()

            RadialGradient(
                colors: [ColorTheme.Base.error.color.opacity(0.15), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(ColorTheme.Backgrounds.surfaceVariant.color)
                        .frame(width: 100, height: 100)
                    Circle()
                        .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
                        .frame(width: 100, height: 100)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(ColorTheme.Base.error.color)
                    Circle()
                        .trim(from: 0, to: trimFraction)
                        .stroke(
                            ColorTheme.Base.error.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 114, height: 114)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: trimFraction)
                }

                VStack(spacing: 12) {
                    Text("Conversation will auto-lock in")
                        .font(for: .h1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Text("Tap to keep active")
                        .font(for: .h4)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onReceive(timer) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                onExpired()
            }
        }
    }

    private var trimFraction: Double {
        Double(secondsRemaining) / Double(totalSeconds)
    }
}
