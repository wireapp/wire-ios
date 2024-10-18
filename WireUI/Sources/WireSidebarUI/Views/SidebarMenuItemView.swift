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

struct SidebarMenuItemView: View {

    // MARK: - Constants

    private let backgroundCornerRadius: CGFloat = 12

    // MARK: - Properties

    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.wireAccentColorMapping) private var wireAccentColorMapping

    @Environment(\.sidebarMenuItemTitleForegroundColor) private var titleForegroundColor
    @Environment(\.sidebarMenuItemLinkIconForegroundColor) private var linkIconForegroundColor
    @Environment(\.sidebarMenuItemIsSelectedTitleForegroundColor) private var isSelectedTitleForegroundColor

    private var accentColor: UIColor {
        wireAccentColorMapping?.uiColor(for: wireAccentColor) ?? .systemGray
    }

    /// The `systemName` which is passed into `SwiftUI.Image`.
    private(set) var icon: String
    private(set) var iconSize: CGSize?

    /// If `true` an icon will be shown at the trailing side of the title.
    private(set) var isLink = false

    /// Displays a highlighted/selection state.
    /// If `true`, ".fill" will be appended to the value of the `icon` property.
    private(set) var isHighlighted = false

    private(set) var title: () -> Text
    private(set) var action: () -> Void

    // MARK: -

    var body: some View {
        Button(action: action) {
            HStack {
                Label {
                    title()
                        .foregroundStyle(isHighlighted ? isSelectedTitleForegroundColor : titleForegroundColor)
                } icon: {
                    let iconSystemNameSuffix = isHighlighted ? ".fill" : ""
                    let icon = Image(systemName: icon + iconSystemNameSuffix)
                        .foregroundStyle(isHighlighted ? isSelectedTitleForegroundColor : Color(accentColor))
                        .background(GeometryReader { geometryProxy in
                            Color.clear.preference(key: SidebarMenuItemMinIconSizeKey.self, value: geometryProxy.size)
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
                        .foregroundStyle(isHighlighted ? isSelectedTitleForegroundColor : linkIconForegroundColor)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: backgroundCornerRadius))
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color(isHighlighted ? accentColor : .clear))
            .cornerRadius(backgroundCornerRadius)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

// MARK: - Min Icon Size Preference Key

struct SidebarMenuItemMinIconSizeKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value.width = max(value.width, nextValue().width)
        value.height = max(value.height, nextValue().height)
    }
}

// MARK: - View Modifiers + Environment

extension View {
    func sidebarMenuItemTitleForegroundColor(_ titleForegroundColor: Color) -> some View {
        modifier(SidebarMenuItemTitleForegroundColorViewModifier(titleForegroundColor: titleForegroundColor))
    }

    func sidebarMenuItemLinkIconForegroundColor(_ linkIconForegroundColor: Color) -> some View {
        modifier(SidebarMenuItemLinkIconForegroundColorViewModifier(linkIconForegroundColor: linkIconForegroundColor))
    }

    func sidebarMenuItemIsSelectedTitleForegroundColor(_ isSelectedTitleForegroundColor: Color) -> some View {
        modifier(SidebarMenuItemIsSelectedTitleForegroundColorViewModifier(isSelectedTitleForegroundColor: isSelectedTitleForegroundColor))
    }
}

private extension EnvironmentValues {
    var sidebarMenuItemTitleForegroundColor: Color {
        get { self[SidebarMenuItemTitleForegroundColorKey.self] }
        set { self[SidebarMenuItemTitleForegroundColorKey.self] = newValue }
    }

    var sidebarMenuItemLinkIconForegroundColor: Color {
        get { self[SidebarMenuItemLinkIconForegroundColorKey.self] }
        set { self[SidebarMenuItemLinkIconForegroundColorKey.self] = newValue }
    }

    var sidebarMenuItemIsSelectedTitleForegroundColor: Color {
        get { self[SidebarMenuItemIsSelectedTitleForegroundColorKey.self] }
        set { self[SidebarMenuItemIsSelectedTitleForegroundColorKey.self] = newValue }
    }
}

struct SidebarMenuItemTitleForegroundColorViewModifier: ViewModifier {
    var titleForegroundColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarMenuItemTitleForegroundColor, titleForegroundColor)
    }
}

private struct SidebarMenuItemTitleForegroundColorKey: EnvironmentKey {
    static let defaultValue = Color.primary
}

struct SidebarMenuItemLinkIconForegroundColorViewModifier: ViewModifier {
    var linkIconForegroundColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarMenuItemLinkIconForegroundColor, linkIconForegroundColor)
    }
}

private struct SidebarMenuItemLinkIconForegroundColorKey: EnvironmentKey {
    static let defaultValue = Color.primary.opacity(0.6)
}

struct SidebarMenuItemIsSelectedTitleForegroundColorViewModifier: ViewModifier {
    var isSelectedTitleForegroundColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarMenuItemIsSelectedTitleForegroundColor, isSelectedTitleForegroundColor)
    }
}

private struct SidebarMenuItemIsSelectedTitleForegroundColorKey: EnvironmentKey {
    static let defaultValue = Color.white
}

// MARK: - Previews

#Preview {
    SidebarMenuItemPreview()
}
