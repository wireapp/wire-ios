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
// TODO: remove underscore
private let cornerRadius_: CGFloat = 12

struct SidebarMenuItem: View {

    /// The `systemName` which is passed into `SwiftUI.Image`.
    /// If `isHighlighted` is `true`, ".fill" will be appended to the icon name.
    private(set) var icon: String
    private(set) var iconSize: CGSize?
    /// If `true` an icon will be shown at the trailing side of the title.
    private(set) var isLink = false
    /// Displays a highlighted/selection state.
    private(set) var isHighlighted = false

    private(set) var title: () -> Text
    private(set) var action: () -> Void

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
                        let icon = Image(systemName: icon + iconSystemNameSuffix)
                            .foregroundStyle(isHighlighted ? isPressedForegroundColor : accentColor_)
                            .background(GeometryReader { geometryProxy in
                                Color.clear.preference(key: SidebarMenuItemIconSizeKey.self, value: geometryProxy.size)
                            })
                        if let iconSize {
                            icon.frame(minWidth: iconSize.width, minHeight: iconSize.height)
                        } else {
                            icon
                        }
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

// MARK: - Helpers

private struct IsPressedReader<Content>: View where Content: View {
    @Environment(\.isPressed) private var isPressed
    @ViewBuilder let content: (_ isPressed: Bool) -> Content
    var body: some View { content(isPressed) }
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

// MARK: - Button Style

private struct SidebarMenuItemStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isPressed, configuration.isPressed)
    }
}

// MARK: - Preference Key

struct SidebarMenuItemIconSizeKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value.width = max(value.width, nextValue().width)
        value.height = max(value.height, nextValue().height)
    }
}

// MARK: - Previews

#Preview {
    VStack {
        SidebarMenuItemContainer { iconSize in
            SidebarMenuItem(icon: "text.bubble", iconSize: iconSize, isHighlighted: false, title: { Text("Regular") }, action: { print("show all conversations") })
            SidebarMenuItem(icon: "gamecontroller", iconSize: iconSize, isHighlighted: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
            SidebarMenuItem(icon: "person.3", iconSize: iconSize, isLink: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
        }
        Rectangle()
            .frame(height: 1)
        SidebarMenuItemContainer { iconSize in
            SidebarMenuItem(icon: "text.bubble", iconSize: iconSize, isHighlighted: false, title: { Text("Small Icon") }, action: { print("show all conversations") })
            SidebarMenuItem(icon: "brain", iconSize: iconSize, isHighlighted: false, title: { Text("Little larger Icon") }, action: { print("show all conversations") })
        }
        Text("Make sure, the icons' sizes match only within their menu! (the icon sizes of the menu below are independent from the ones above)")
            .font(.caption)
    }
    .frame(width: 260)
}

private struct SidebarMenuItemContainer<Content>: View where Content: View {

    @State private var iconSize: CGSize?

    @ViewBuilder let content: (_ iconSize: CGSize?) -> Content

    var body: some View {
        VStack {
            content(iconSize)
                .onPreferenceChange(SidebarMenuItemIconSizeKey.self) { newIconSize in
                    guard var iconSize else { return iconSize = newIconSize }
                    iconSize.width = max(iconSize.width, newIconSize.width)
                    iconSize.height = max(iconSize.height, newIconSize.height)
                    self.iconSize = iconSize
                }
        }
    }
}
