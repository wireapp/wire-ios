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

@MainActor @ViewBuilder
func SidebarMenuItemPreview() -> some View {
    VStack {
        // Displaying two separate menus here in order to verify, that
        // the size of the icons is constant only within one menu.
        SidebarMenuItemContainer { iconSize in
            SidebarMenuItemView(icon: "text.bubble", iconSize: iconSize, isHighlighted: false, title: { Text("Regular") }, action: { print("show all conversations") })
            SidebarMenuItemView(icon: "gamecontroller", iconSize: iconSize, isHighlighted: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
            SidebarMenuItemView(icon: "person.3", iconSize: iconSize, isLink: true, title: { Text("Initially highlighted") }, action: { print("show all conversations") })
        }
        Divider()
        SidebarMenuItemContainer { iconSize in
            SidebarMenuItemView(icon: "text.bubble", iconSize: iconSize, isHighlighted: false, title: { Text("Small Icon") }, action: { print("show all conversations") })
            SidebarMenuItemView(icon: "brain", iconSize: iconSize, isHighlighted: false, title: { Text("Little larger Icon") }, action: { print("show all conversations") })
        }
    }
    .frame(width: 260)
}

private struct SidebarMenuItemContainer<Content>: View where Content: View {

    @State private var iconSize: CGSize?

    @ViewBuilder let content: (_ iconSize: CGSize?) -> Content

    var body: some View {
        VStack {
            content(iconSize)
                .onPreferenceChange(SidebarMenuItemMinIconSizeKey.self) { newIconSize in
                    guard var iconSize else { return iconSize = newIconSize }
                    iconSize.width = max(iconSize.width, newIconSize.width)
                    iconSize.height = max(iconSize.height, newIconSize.height)
                    self.iconSize = iconSize
                }
        }
    }
}
