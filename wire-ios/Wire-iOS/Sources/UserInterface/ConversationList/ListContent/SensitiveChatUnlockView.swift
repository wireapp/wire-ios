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

import LocalAuthentication
import SwiftUI
import WireDesign

struct SensitiveChatUnlockView: View {
    let conversationName: String
    let mainColor: Color
    let requiresAuthentication: Bool
    let onUnlocked: () -> Void
    let onDismiss: () -> Void

    init(
        conversationName: String,
        mainColor: Color,
        requiresAuthentication: Bool = true,
        onUnlocked: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.conversationName = conversationName
        self.mainColor = mainColor
        self.requiresAuthentication = requiresAuthentication
        self.onUnlocked = onUnlocked
        self.onDismiss = onDismiss
    }

    @State private var authenticationFailed = false

    private var backgroundColor: Color {
        ColorTheme.Backgrounds.background.color
    }

    private var foregroundColor: Color {
        ColorTheme.Backgrounds.onSurface.color
    }

    private var secondaryForegroundColor: Color {
        ColorTheme.Base.secondaryText.color
    }

    private var placeholderColor: Color {
        ColorTheme.Backgrounds.backgroundVariant.color
    }

    private var lockIconBackgroundColor: Color {
        ColorTheme.Backgrounds.surfaceVariant.color
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Blurred placeholder area
                RoundedRectangle(cornerRadius: 12)
                    .fill(placeholderColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .overlay {
                        // Simulated blurred conversation rows
                        VStack(spacing: 12) {
                            ForEach(0 ..< 3, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(ColorTheme.Strokes.outline.color)
                                        .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(ColorTheme.Strokes.outline.color)
                                            .frame(width: 120, height: 12)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(ColorTheme.Strokes.outline.color.opacity(0.6))
                                            .frame(width: 180, height: 10)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .blur(radius: 6)
                    .padding(.horizontal, 16)

                Spacer()

                // Lock icon
                Image(systemName: "lock.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        mainColor,
                        lockIconBackgroundColor
                    )
                    .font(.system(size: 64))
                    .padding(.bottom, 16)

                // Conversation name
                Text(conversationName)
                    .font(.title2.bold())
                    .foregroundStyle(foregroundColor)
                    .padding(.bottom, 4)

                // Subtitle
                Text("This is a sensitive conversation")
                    .font(.subheadline)
                    .foregroundStyle(secondaryForegroundColor)
                    .padding(.bottom, 32)

                if requiresAuthentication {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: biometricIconName)
                                .font(.system(.headline, weight: .semibold))
                            Text("Unlock to View")
                                .font(.headline)
                        }
                        .foregroundStyle(ColorTheme.Base.onWarning.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(mainColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                } else {
                    Button {
                        onUnlocked()
                    } label: {
                        Text("Show")
                            .font(.headline)
                            .foregroundStyle(ColorTheme.Base.onWarning.color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(mainColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    // MARK: - Biometrics

    private var biometricIconName: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }

    // MARK: - Authentication

    /// Triggers the system device passcode prompt (no biometrics).
    private func authenticateWithDevicePasscode() {
        let context = LAContext()
        // Disable biometrics so the system shows only the passcode keypad
        context.localizedFallbackTitle = ""

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock \(conversationName)"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    onUnlocked()
                } else {
                    authenticationFailed = true
                }
            }
        }
    }

    /// Triggers biometric authentication (Face ID or Touch ID).
    private func authenticateWithBiometrics() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available, fall back to device passcode
            authenticateWithDevicePasscode()
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock \(conversationName)"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    onUnlocked()
                } else {
                    authenticationFailed = true
                }
            }
        }
    }
}
