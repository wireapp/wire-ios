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

// MARK: - Configuration

struct CallActionsConfiguration {
    var isMuted: Bool
    var isSendingVideo: Bool
    var canAcceptVideoCalls: Bool
    var canToggleMediaType: Bool
    var isSpeakerEnabled: Bool
    var canSpeakerBeToggled: Bool
}

extension CallActionsConfiguration {
    init(_ configuration: CallInfoConfiguration) {
        isMuted = configuration.isMuted
        isSendingVideo = configuration.mediaState.isSendingVideo
        canAcceptVideoCalls = configuration.permissions.canAcceptVideoCalls
        canToggleMediaType = configuration.canToggleMediaType
        isSpeakerEnabled = configuration.mediaState.isSpeakerEnabled
        canSpeakerBeToggled = configuration.mediaState.canSpeakerBeToggled
    }
}

// MARK: - View

/// Shared active-call button container used in both portrait (`.horizontal`) and
/// landscape (`.vertical`) orientations. See `CallActionsView` for Incoming-call controls.
struct ActiveCallActionsView: View {

    let axis: Axis
    var isReactionsTrayOpen: Bool = false
    var configuration: CallActionsConfiguration
    let performAction: (CallAction) -> Void

    var body: some View {
        if axis == .vertical {
            VStack(spacing: 0) {
                muteButton.frame(maxWidth: .infinity, maxHeight: .infinity)
                videoButton.frame(maxWidth: .infinity, maxHeight: .infinity)
                speakerButton.frame(maxWidth: .infinity, maxHeight: .infinity)
                callReactionButton.frame(maxWidth: .infinity, maxHeight: .infinity)
                hangupButton.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)

        } else {
            VStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    muteButton.frame(maxWidth: .infinity)
                    videoButton.frame(maxWidth: .infinity)
                    speakerButton.frame(maxWidth: .infinity)
                    callReactionButton.frame(maxWidth: .infinity)
                    hangupButton.frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Buttons

    private var muteButton: some View {
        CallActionButton(
            systemImage: configuration.isMuted ? "mic.slash.fill" : "mic.fill",
            isSelected: !configuration.isMuted,
            isDestructive: false
        ) { performAction(.toggleMuteState) }
    }

    private var videoButton: some View {
        CallActionButton(
            systemImage: configuration.isSendingVideo ? "video.fill" : "video.slash.fill",
            isSelected: configuration.isSendingVideo && configuration.canAcceptVideoCalls,
            isDestructive: false,
            isEnabled: configuration.canToggleMediaType
        ) { performAction(.toggleVideoState) }
    }

    private var speakerButton: some View {
        CallActionButton(
            systemImage: configuration.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
            isSelected: configuration.isSpeakerEnabled,
            isDestructive: false,
            isEnabled: configuration.canSpeakerBeToggled
        ) { performAction(.toggleSpeakerState) }
    }

    private var callReactionButton: some View {
        CallActionButton(
            systemImage: "face.smiling",
            isSelected: isReactionsTrayOpen,
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

private let previewConfig = CallActionsConfiguration(
    isMuted: false,
    isSendingVideo: true,
    canAcceptVideoCalls: true,
    canToggleMediaType: true,
    isSpeakerEnabled: false,
    canSpeakerBeToggled: true
)

#Preview("Portrait — horizontal row") {
    ActiveCallActionsView(
        axis: .horizontal,
        isReactionsTrayOpen: false,
        configuration: previewConfig,
        performAction: { _ in }
    )
    .frame(height: 72)
    .background(Color(.systemBackground))
    .previewInterfaceOrientation(.portrait)
}

#Preview("Landscape — vertical column", traits: .landscapeRight) {
    HStack {
        Spacer()
        ActiveCallActionsView(
            axis: .vertical,
            isReactionsTrayOpen: true,
            configuration: previewConfig,
            performAction: { _ in }
        )
        .frame(width: 72)
        .frame(maxHeight: .infinity)
        .background(Color(.systemGray6))
        .padding(16)
        .ignoresSafeArea()
    }

    .ignoresSafeArea(.all)
}

#Preview("Muted / video off / speaker on") {
    ActiveCallActionsView(
        axis: .horizontal,
        configuration: CallActionsConfiguration(
            isMuted: true,
            isSendingVideo: false,
            canAcceptVideoCalls: true,
            canToggleMediaType: true,
            isSpeakerEnabled: true,
            canSpeakerBeToggled: true
        ),
        performAction: { _ in }
    )
    .frame(height: 72)
    .background(Color(.systemBackground))
}
