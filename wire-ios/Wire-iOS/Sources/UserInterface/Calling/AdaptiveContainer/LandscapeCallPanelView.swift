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

/// Landscape right-side panel: handle | vertical buttons | participants list.
/// The buttons column is always visible; the participants column is revealed by dragging left.
struct LandscapeCallPanelView: View {

    static let buttonsColumnWidth: CGFloat = 72
    static let participantsColumnWidth: CGFloat = 320
    static let handleWidth: CGFloat = 24

    @ObservedObject var viewModel: CallingContainerViewModel
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 0) {
            dragHandle
            callButtonsColumn
            participantsColumn
        }
        .background(Color(SemanticColors.View.backgroundDefault))
    }

    // MARK: - Handle

    private var dragHandle: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(SemanticColors.View.backgroundCallDragBarIndicator))
                .frame(width: 5, height: 44)
            Spacer()
        }
        .frame(width: Self.handleWidth)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Vertical call buttons

    private var callButtonsColumn: some View {
        VStack(spacing: 16) {
            Spacer()
            if let config = viewModel.callInfoConfiguration {
                LandscapeCallButton(
                    systemImage: config.isMuted ? "mic.slash.fill" : "mic.fill",
                    isSelected: !config.isMuted,
                    isDestructive: false
                ) { perform(.toggleMuteState) }

                LandscapeCallButton(
                    systemImage: config.mediaState.isSendingVideo ? "video.fill" : "video.slash.fill",
                    isSelected: config.mediaState.isSendingVideo && config.permissions.canAcceptVideoCalls,
                    isDestructive: false,
                    isEnabled: config.canToggleMediaType
                ) { perform(.toggleVideoState) }

                LandscapeCallButton(
                    systemImage: config.mediaState.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isSelected: config.mediaState.isSpeakerEnabled,
                    isDestructive: false,
                    isEnabled: config.mediaState.canSpeakerBeToggled
                ) { perform(.toggleSpeakerState) }

                LandscapeCallButton(
                    systemImage: "phone.down.fill",
                    isSelected: false,
                    isDestructive: true
                ) { perform(.terminateCall) }
            }
            Spacer()
        }
        .frame(width: Self.buttonsColumnWidth)
    }

    // MARK: - Participants list

    private var participantsColumn: some View {
        CallingActionsInfoRepresentable(
            viewModel: viewModel,
            isExpanded: $isExpanded,
            hideActionsView: true
        )
        .frame(width: Self.participantsColumnWidth)
    }

    private func perform(_ action: CallAction) {
        viewModel.callViewController?.callingActionsViewPerformAction(action)
    }
}

// MARK: - LandscapeCallButton

private struct LandscapeCallButton: View {

    let systemImage: String
    let isSelected: Bool
    let isDestructive: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .overlay(
                            Circle().stroke(borderColor, lineWidth: 1)
                        )
                )
        }
        .disabled(!isEnabled)
    }

    private var backgroundColor: Color {
        if isDestructive {
            return Color(SemanticColors.Button.backgroundLikeHighlighted)
        }
        return isSelected
            ? Color(SemanticColors.Button.backgroundCallingSelected)
            : Color(SemanticColors.Button.backgroundCallingNormal)
    }

    private var iconColor: Color {
        if isDestructive {
            return Color(SemanticColors.View.backgroundDefaultWhite)
        }
        return isSelected
            ? Color(SemanticColors.Button.iconCallingSelected)
            : Color(SemanticColors.Button.iconCallingNormal)
    }

    private var borderColor: Color {
        if isDestructive { return .clear }
        return isSelected
            ? Color(SemanticColors.Button.borderCallingSelected)
            : Color(SemanticColors.Button.borderCallingNormal)
    }
}
