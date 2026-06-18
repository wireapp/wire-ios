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

/// Shared active-call button container used in both portrait (`.horizontal`) and
/// landscape (`.vertical`) orientations. Incoming-call controls are handled separately.
struct ActiveCallActionsView: View {

    let axis: Axis
    var showDragHandle: Bool = false
    let configuration: CallInfoConfiguration?
    let performAction: (CallAction) -> Void
    var onDragHandleTap: () -> Void = {}

    var body: some View {
        if axis == .vertical {
            VStack(spacing: 16) {
                Spacer()
                if let config = configuration {
                    muteButton(config)
                    videoButton(config)
                    speakerButton(config)
                    hangupButton
                }
                Spacer()
            }
        } else {
            VStack(spacing: 0) {
                if showDragHandle {
                    dragHandle
                }
                if let config = configuration {
                    HStack(spacing: 0) {
                        muteButton(config).frame(maxWidth: .infinity)
                        videoButton(config).frame(maxWidth: .infinity)
                        speakerButton(config).frame(maxWidth: .infinity)
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

    private var hangupButton: some View {
        CallActionButton(
            systemImage: "phone.down.fill",
            isSelected: false,
            isDestructive: true
        ) { performAction(.terminateCall) }
    }

    // MARK: - Drag handle (portrait only)

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(SemanticColors.View.backgroundCallDragBarIndicator))
            .frame(width: 130, height: 5)
            .padding(.bottom, 8)
            .contentShape(Rectangle().inset(by: -8))
            .onTapGesture(perform: onDragHandleTap)
            .frame(maxWidth: .infinity)
    }
}
