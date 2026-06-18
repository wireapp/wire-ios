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
import WireLocators

/// Shared active-call button container used in both portrait (`.horizontal`) and
/// landscape (`.vertical`) orientations. Incoming-call controls are handled separately.
struct ActiveCallActionsView: View {

    let axis: Axis
    let configuration: CallInfoConfiguration?
    let performAction: (CallAction) -> Void
    var onDragHandleTap: () -> Void = {}

    var body: some View {
        if axis == .vertical {
            if let config = configuration {
                VStack(spacing: 16) {
                    Spacer(minLength: 0)
                    muteButton(config)
                    Spacer(minLength: 0)
                    videoButton(config)
                    Spacer(minLength: 0)
                    speakerButton(config)
                    Spacer(minLength: 0)
                    callReactionButton
                    Spacer(minLength: 0)
                    hangupButton
                    Spacer(minLength: 0)
                }
            }
        } else {
            VStack(spacing: 0) {
                if let config = configuration {
                    HStack(spacing: 0) {
                        muteButton(config).frame(maxWidth: .infinity)
                        videoButton(config).frame(maxWidth: .infinity)
                        speakerButton(config).frame(maxWidth: .infinity)
                        callReactionButton.frame(maxWidth: .infinity)
                        hangupButton.frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 64)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Buttons

    private func muteButton(_ config: CallInfoConfiguration) -> some View {
        CallActionButton(
            systemImage: config.isMuted ? "mic.slash.fill" : "mic.fill",
            isSelected: !config.isMuted,
            isDestructive: false
        ) { performAction(.toggleMuteState) }
    }

    private func videoButton(_ config: CallInfoConfiguration) -> some View {
        CallActionButton(
            systemImage: config.mediaState.isSendingVideo ? "video.fill" : "video.slash.fill",
            isSelected: config.mediaState.isSendingVideo && config.permissions.canAcceptVideoCalls,
            isDestructive: false,
            isEnabled: config.canToggleMediaType
        ) { performAction(.toggleVideoState) }
    }

    private func speakerButton(_ config: CallInfoConfiguration) -> some View {
        CallActionButton(
            systemImage: config.mediaState.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
            isSelected: config.mediaState.isSpeakerEnabled,
            isDestructive: false,
            isEnabled: config.mediaState.canSpeakerBeToggled
        ) { performAction(.toggleSpeakerState) }
    }

    private var callReactionButton: some View {
        CallActionButton(
            systemImage: "face.smiling",
            isSelected: false,
            isDestructive: false
        ) { performAction(.toggleReactionsTray) }
        .accessibilityIdentifier(Locators.OngoingCallPage.callReactionButton)
        .accessibilityLabel(L10n.Localizable.Voice.CallReactionButton.title)
    }

    private var hangupButton: some View {
        CallActionButton(
            systemImage: "phone.down.fill",
            isSelected: false,
            isDestructive: true
        ) { performAction(.terminateCall) }
    }
}

// MARK: - Previews

#Preview("Landscape — vertical column") {
    HStack {
        _PreviewVerticalButtons()
            .background(Color.yellow.opacity(0.15))
            .ignoresSafeArea()
    }
    .background(Color(.systemGray5))
    .ignoresSafeArea()
}

/// Mirrors the vertical branch of `ActiveCallActionsView` for layout debugging.
private struct _PreviewVerticalButtons: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            CallActionButton(systemImage: "mic.fill", isSelected: true, isDestructive: false) {}
            CallActionButton(systemImage: "video.slash.fill", isSelected: false, isDestructive: false) {}
            CallActionButton(systemImage: "speaker.slash.fill", isSelected: false, isDestructive: false) {}
            CallActionButton(systemImage: "face.smiling", isSelected: false, isDestructive: false) {}
            CallActionButton(systemImage: "phone.down.fill", isSelected: false, isDestructive: true) {}
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

