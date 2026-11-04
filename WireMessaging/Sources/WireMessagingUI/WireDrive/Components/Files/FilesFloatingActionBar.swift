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

struct FilesFloatingActionBar: View {

    struct Action: Identifiable {
        let id: String
        let title: String
        let systemImage: String
        var isEnabled = true
        let perform: () -> Void
    }

    let actions: [Action]

    @Environment(\.isEnabled) private var isEnabled
    @GestureState private var touchLocation: CGPoint?
    @State private var itemFrames: [String: CGRect] = [:]

    private let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
    private let coordinateSpaceName = "FilesFloatingActionBar"

    private var highlightedActionID: String? {
        guard let touchLocation else { return nil }
        return actions.first { action in
            action.isEnabled && itemFrames[action.id]?.contains(touchLocation) == true
        }?.id
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                Image(systemName: action.systemImage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .shadow(
                        color: ColorTheme.Backgrounds.onSurface.color
                            .opacity(highlightedActionID == action.id ? 0.8 : 0),
                        radius: 10
                    )
                    .opacity(isEnabled && action.isEnabled ? 1 : 0.3)
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .named(coordinateSpaceName))
                    } action: {
                        itemFrames[action.id] = $0
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(action.title)
                    .accessibilityIdentifier(action.id)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { if isEnabled, action.isEnabled { action.perform() } }
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .font(.title2)
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        .background {
            if #available(iOS 26, macOS 26, *) {
                shape.fill(.clear).glassEffect(.regular, in: shape)
            } else {
                shape.fill(.ultraThinMaterial)
            }
        }
        .clipShape(shape)
        .contentShape(shape)
        .gesture(dragGesture, including: isEnabled ? .all : .subviews)
        .scaleEffect(touchLocation != nil ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: touchLocation != nil)
        .animation(.easeOut(duration: 0.15), value: highlightedActionID)
    }

    /// Tracks the finger from touch down so the user can slide between actions.
    /// The highlighted action is triggered on release; releasing outside any action cancels.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
            .updating($touchLocation) { value, state, _ in
                state = value.location
            }
            .onEnded { value in
                actions.first { action in
                    action.isEnabled && itemFrames[action.id]?.contains(value.location) == true
                }?.perform()
            }
    }
}

#Preview {
    @Previewable @State var lastAction = "Press an action"

    VStack(spacing: 24) {
        Text(lastAction)

        FilesFloatingActionBar(actions: [
            .init(
                id: "moveToFolder",
                title: "Move to Folder",
                systemImage: "folder",
                perform: { lastAction = "Move to Folder" }
            ),
            .init(
                id: "delete",
                title: "Delete",
                systemImage: "trash",
                perform: { lastAction = "Delete" }
            )
        ])
    }
    .padding(32)
    .background(ColorTheme.Backgrounds.background.color)
}
