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

enum CallPanelLayout {
    case portrait
    case landscape(side: HorizontalEdge)
}

/// Unified call panel used in both portrait (bottom sheet) and landscape (side panel).
/// Portrait: VStack — horizontal drag handle | horizontal buttons row | participants list.
/// Landscape: HStack — vertical drag handle | vertical buttons column | participants list.
struct CallPanelView: View {

    // Landscape constants
    static let buttonsColumnWidth: CGFloat = 72
    static let participantsColumnWidth: CGFloat = 320
    static let handleWidth: CGFloat = 24

    // Portrait constants (mirror landscape dimensions)
    static let handleHeight: CGFloat = 24
    static let buttonsRowHeight: CGFloat = 72
    static let emojiTrayHeight: CGFloat = 72

    @ObservedObject var viewModel: CallingContainerViewModel
    @Binding var isExpanded: Bool
    @Binding var isReactionsTrayOpen: Bool
    var layout: CallPanelLayout = .portrait

    var body: some View {
        switch layout {
        case .portrait:
            portraitBody
        case .landscape(let side):
            landscapeBody(side: side)
        }
    }

    // MARK: - Portrait layout

    private var portraitBody: some View {
        VStack(spacing: 0) {
            portraitDragHandle
            if isReactionsTrayOpen {
                CallReactionsTray(axis: .horizontal) { emoji in
                    perform(.sendReaction(emoji: emoji))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            portraitCallButtonsRow
            portraitParticipantsSection
        }
        .background(Color(SemanticColors.View.backgroundDefault))
        .animation(.easeInOut(duration: 0.2), value: isReactionsTrayOpen)
    }

    private var portraitDragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(SemanticColors.View.backgroundCallDragBarIndicator))
                .frame(width: 44, height: 5)
            Spacer()
        }
        .frame(height: Self.handleHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }

    private var portraitCallButtonsRow: some View {
        ActiveCallActionsView(
            axis: .horizontal,
            isReactionsTrayOpen: isReactionsTrayOpen,
            configuration: viewModel.callInfoConfiguration,
            performAction: perform
        )
        .frame(height: Self.buttonsRowHeight)
    }

    private var portraitParticipantsSection: some View {
        CallingActionsInfoRepresentable(
            viewModel: viewModel,
            isExpanded: $isExpanded,
            hideActionsView: true
        )
    }

    // MARK: - Landscape layout

    private func landscapeBody(side: HorizontalEdge) -> some View {
        HStack(spacing: 0) {
            if side == .trailing {
                landscapeDragHandle
                if isReactionsTrayOpen {
                    emojiColumn
                        .frame(width: Self.buttonsColumnWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                callButtonsColumn
                participantsColumn
            } else {
                participantsColumn
                callButtonsColumn
                if isReactionsTrayOpen {
                    emojiColumn
                        .frame(width: Self.buttonsColumnWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                landscapeDragHandle
            }
        }
        .background(Color(SemanticColors.View.backgroundDefault))
        .animation(.easeInOut(duration: 0.2), value: isReactionsTrayOpen)
    }

    private var emojiColumn: some View {
        CallReactionsTray(axis: .vertical) { emoji in
            perform(.sendReaction(emoji: emoji))
        }
    }

    private var landscapeDragHandle: some View {
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

    private var callButtonsColumn: some View {
        ActiveCallActionsView(
            axis: .vertical,
            isReactionsTrayOpen: isReactionsTrayOpen,
            configuration: viewModel.callInfoConfiguration,
            performAction: perform
        )
        .frame(width: Self.buttonsColumnWidth)
    }

    private var participantsColumn: some View {
        CallingActionsInfoRepresentable(
            viewModel: viewModel,
            isExpanded: $isExpanded,
            hideActionsView: true
        )
        .frame(width: Self.participantsColumnWidth)
    }

    private func perform(_ action: CallAction) {
        switch action {
        case .toggleReactionsTray:
            withAnimation(.easeInOut(duration: 0.2)) { isReactionsTrayOpen.toggle() }
        default:
            viewModel.callViewController?.callingActionsViewPerformAction(action)
        }
    }
}
