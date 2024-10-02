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
import WireFoundation

public struct SidebarView<AccountImageView>: View where AccountImageView: View {

    @Environment(\.sidebarBackgroundColor) private var sidebarBackgroundColor

    public var accountInfo: SidebarAccountInfo?
    @Binding public var selectedMenuItem: SidebarMenuItem

    private(set) var accountImageAction: () -> Void
    private(set) var connectAction: () -> Void
    private(set) var supportAction: () -> Void

    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    @State private var iconSize: CGSize?

    public init(
        accountInfo: SidebarAccountInfo,
        selectedMenuItem: Binding<SidebarMenuItem>,
        accountImageAction: @escaping () -> Void,
        connectAction: @escaping () -> Void,
        supportAction: @escaping () -> Void,
        accountImageView: @escaping (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AccountImageView
    ) {
        self.accountInfo = accountInfo
        _selectedMenuItem = selectedMenuItem
        self.accountImageAction = accountImageAction
        self.connectAction = connectAction
        self.supportAction = supportAction
        self.accountImageView = accountImageView
    }

    public var body: some View {
        ZStack {
            // background color
            Rectangle()
                .foregroundStyle(sidebarBackgroundColor)
                .ignoresSafeArea()

            // content
            VStack(alignment: .leading, spacing: 0) {
                accountInfoView
                    .onTapGesture(perform: accountImageAction)
                    .padding(.horizontal, 24)
                    .padding(.vertical)

                let menuItemsScrollView = ScrollView(.vertical) { scrollableMenuItems }
                if #available(iOS 16.4, *) {
                    menuItemsScrollView
                        .scrollBounceBehavior(.basedOnSize)
                } else {
                    menuItemsScrollView
                }

                // bottom menu items
                Group {
                    menuItem(.settings)

                    SidebarMenuItemView(icon: "questionmark.circle", iconSize: iconSize, isLink: true) {
                        Text("sidebar.support.title", bundle: .module)
                    } action: {
                        supportAction()
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom)
            .frame(maxWidth: .infinity)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onPreferenceChange(SidebarMenuItemMinIconSizeKey.self) { newIconSize in
            guard var iconSize else { return iconSize = newIconSize }
            iconSize.width = max(iconSize.width, newIconSize.width)
            iconSize.height = max(iconSize.height, newIconSize.height)
            self.iconSize = iconSize
        }
    }

    @ViewBuilder
    private var accountInfoView: some View {
        if let accountInfo {
            SidebarAccountInfoView(
                displayName: accountInfo.displayName,
                username: accountInfo.username,
                accountImageView: { accountImageView(accountInfo.accountImage, accountInfo.availability) }
            )
        }
    }

    @ViewBuilder
    private var scrollableMenuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItemHeader("sidebar.conversation_filter.title", addTopPadding: false)
            let conversationFilters = [SidebarMenuItem.all, .favorites, .groups, .oneOnOne, .archive]
            ForEach(conversationFilters, id: \.self) { conversationFilter in
                menuItem(conversationFilter)
            }

            menuItemHeader("sidebar.contacts.title")
            SidebarMenuItemView(icon: "person.badge.plus", iconSize: iconSize) {
                Text("sidebar.contacts.connect.title", bundle: .module)
            } action: {
                connectAction()
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func menuItemHeader(_ key: LocalizedStringKey, addTopPadding: Bool = true) -> some View {
        let text = Text(key, bundle: .module)
            .wireTextStyle(.h2)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        if addTopPadding {
            text
                .padding(.top)
        } else {
            text
        }
    }

    private func menuItem(_ menuItem: SidebarMenuItem) -> some View {
        let text: Text
        let icon: String
        switch menuItem {
        case .all:
            text = Text("sidebar.conversation_filter.all.title", bundle: .module)
            icon = "text.bubble"

        case .favorites:
            text = Text("sidebar.conversation_filter.favorites.title", bundle: .module)
            icon = "star"

        case .groups:
            text = Text("sidebar.conversation_filter.groups.title", bundle: .module)
            icon = "person.3"

        case .oneOnOne:
            text = Text("sidebar.conversation_filter.oneOnOneConversations.title", bundle: .module)
            icon = "person"

        case .archive:
            text = Text("sidebar.conversation_filter.archived.title", bundle: .module)
            icon = "archivebox"

        case .settings:
            text = Text("sidebar.settings.title", bundle: .module)
            icon = "gearshape"
        }

        return SidebarMenuItemView(
            icon: icon,
            iconSize: iconSize,
            isLink: false,
            isHighlighted: selectedMenuItem == menuItem,
            title: { text },
            action: { selectedMenuItem = menuItem }
        )
    }
}

// MARK: - View Modifiers + Environment

extension View {
    func sidebarBackgroundColor(_ sidebarBackgroundColor: Color) -> some View {
        modifier(SidebarBackgroundColorViewModifier(sidebarBackgroundColor: sidebarBackgroundColor))
    }
}

private extension EnvironmentValues {
    var sidebarBackgroundColor: Color {
        get { self[SidebarBackgroundColorKey.self] }
        set { self[SidebarBackgroundColorKey.self] = newValue }
    }
}

struct SidebarBackgroundColorViewModifier: ViewModifier {
    var sidebarBackgroundColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarBackgroundColor, sidebarBackgroundColor)
    }
}

private struct SidebarBackgroundColorKey: EnvironmentKey {
    static let defaultValue = Color(uiColor: .systemGray5)
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    SidebarPreview()
}
