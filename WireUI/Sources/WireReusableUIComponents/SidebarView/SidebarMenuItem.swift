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
                HStack {

                    let iconSystemNameSuffix = isHighlighted != isPressed ? ".fill" : ""
                    Label {
                        title()
                            .foregroundStyle(isPressed ? isPressedForegroundColor : titleForegroundColor)
                    } icon: {
                        Image(systemName: icon + iconSystemNameSuffix)
                            .foregroundStyle(isPressed ? isPressedForegroundColor : accentColor_)
                    }

                    Spacer()

                    if isLink {
                        Image(systemName: "arrow.up.forward.square")
                            .foregroundStyle(isPressed ? isPressedForegroundColor : linkIconForegroundColor)
                    }
                }
            }
        }
        .buttonStyle(SidebarMenuItemStyle())
    }
}

private struct IsPressedReader<Content>: View where Content: View {
    @Environment(\.isPressed) private var isPressed
    let content: (_ isPressed: Bool) -> Content
    var body: some View { content(isPressed) }
}

private struct SidebarMenuItemStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        let cornerRadius: CGFloat = 12
        configuration.label
            .environment(\.isPressed, configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? accentColor_ : .clear)
            .cornerRadius(cornerRadius)
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
