//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

private let titleForegroundColor = Color(ColorTheme.Backgrounds.onBackground)
private let linkIconForegroundColor = Color(ColorTheme.Base.secondaryText)
private let isPressedForegroundColor = Color(ColorTheme.Base.onPrimary)
// TODO: get from Environment
private let accentColor_ = Color(ColorTheme.Base.primary)

private let cornerRadius_: CGFloat = 12

struct SidebarMenuItem: View {

    /// The `systemName` which is passed into `SwiftUI.Image`.
    /// If `isHighlighted` is `true`, ".fill" will be appended to the icon name.
    var icon: String
    /// If `true` an icon will be shown at the trailing side of the title.
    var isLink = false
    /// Displays a highlighted/selection state.
    var isHighlighted = false

    var title: () -> Text
    var action: () -> Void

    var body: some View {

        Button(action: action) {
            IsPressedReader { isPressed in
                let isHighlighted = isHighlighted != isPressed
                HStack {

                    Label {
                        title()
                            .foregroundStyle(isHighlighted ? isPressedForegroundColor : titleForegroundColor)
                    } icon: {
                        let iconSystemNameSuffix = isHighlighted ? ".fill" : ""
                        Image(systemName: icon + iconSystemNameSuffix)
                            .foregroundStyle(isHighlighted ? isPressedForegroundColor : accentColor_)
                    }

                    Spacer()

                    if isLink {
                        Image(systemName: "arrow.up.forward.square")
                            .foregroundStyle(isHighlighted ? isPressedForegroundColor : linkIconForegroundColor)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius_))
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(isHighlighted ? accentColor_ : .clear)
                .cornerRadius(cornerRadius_)
            }
        }
        .buttonStyle(SidebarMenuItemStyle())
    }
}

private struct IsPressedReader<Content>: View where Content: View {
    @Environment(\.isPressed) private var isPressed
    @ViewBuilder let content: (_ isPressed: Bool) -> Content
    var body: some View { content(isPressed) }
}

private struct SidebarMenuItemStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isPressed, configuration.isPressed)
    }
}

private extension EnvironmentValues {

    struct IsPressedKey: EnvironmentKey {
        static let defaultValue = false
    }

    var isPressed: Bool {
        get { self[IsPressedKey.self] }
        set { self[IsPressedKey.self] = newValue }
    }
}

extension View {
    func myCustomValue(_ isPressed: Bool) -> some View {
        environment(\.isPressed, isPressed)
    }
}

// MARK: - Previews

#Preview {
    VStack {
        SidebarMenuItem(icon: "text.bubble", isHighlighted: false, title: { Text("Regular") }, action: { print("show all conversations") })
        SidebarMenuItem(icon: "star", isHighlighted: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
        SidebarMenuItem(icon: "person.3", isLink: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
    }
    .frame(width: 250)
}
