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

public struct SidebarView<AccountImageView: View, LegalHoldIndicatorView: View>: View {

    @Environment(\.sidebarMenuHeaderForegroundColor) private var menuHeaderForegroundColor
    @Environment(\.sidebarBackgroundColor) private var backgroundViewColor

    public var accountInfo: SidebarAccountInfo?
    @Binding public var selectedMenuItem: SidebarSelectableMenuItem

    private(set) var accountImageAction: () -> Void
    private(set) var foldersAction: (CGRect) -> Void
    private(set) var connectAction: () -> Void
    private(set) var supportAction: () -> Void

    private(set) var accountImageView: SidebarViewController.AccountImageViewBuilder<AccountImageView>
    private(set) var legalHoldIndicatorView: () -> LegalHoldIndicatorView

    @State private var iconSize: CGSize?

    public init(
        accountInfo: SidebarAccountInfo,
        selectedMenuItem: Binding<SidebarSelectableMenuItem>,
        accountImageAction: @escaping () -> Void,
        foldersAction: @escaping (_ buttonFrame: CGRect) -> Void,
        connectAction: @escaping () -> Void,
        supportAction: @escaping () -> Void,
        accountImageView: @escaping SidebarViewController.AccountImageViewBuilder<AccountImageView>,
        legalHoldIndicatorView: @escaping () -> LegalHoldIndicatorView
    ) {
        self.accountInfo = accountInfo
        _selectedMenuItem = selectedMenuItem
        self.accountImageAction = accountImageAction
        self.foldersAction = foldersAction
        self.connectAction = connectAction
        self.supportAction = supportAction
        self.accountImageView = accountImageView
        self.legalHoldIndicatorView = legalHoldIndicatorView
    }

    public var body: some View {
        ZStack {
            // background color
            Rectangle()
                .foregroundStyle(backgroundViewColor)
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
                    selectableMenuItem(.settings)
                    nonselectableMenuItem(.support)
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

    @ViewBuilder private var accountInfoView: some View {
        if let accountInfo {
            SidebarAccountInfoView(
                displayName: accountInfo.displayName,
                username: accountInfo.username,
                isE2EICertified: accountInfo.isE2EICertified,
                isVerified: accountInfo.isVerified,
                isLegalHoldIndicatorVisible: accountInfo.isLegalHoldEnabled,
                accountImageView: { accountImageView(accountInfo.accountImageSource, accountInfo.availability, accountInfo.showNotificationsBadge) },
                legalHoldIndicatorView: { legalHoldIndicatorView() }
            )
        }
    }

    @ViewBuilder private var scrollableMenuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItemHeader(L10n.Sidebar.ConversationFilter.title, addTopPadding: false)
            let conversationFilters: [SidebarSelectableMenuItem] = [
                .all,
                .favorites,
                .groups,
                .oneOnOne,
                .folders,
                .archive
            ]
            ForEach(conversationFilters, id: \.self) { conversationFilter in
                selectableMenuItem(conversationFilter)
            }

            menuItemHeader(L10n.Sidebar.Contacts.title)
            nonselectableMenuItem(.connect)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func menuItemHeader(_ title: String, addTopPadding: Bool = true) -> some View {
        let text = Text(title)
            .foregroundStyle(menuHeaderForegroundColor)
            .wireTextStyle(.h2)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .accessibilityAddTraits(.isHeader)
        if addTopPadding {
            text.padding(.top)
        } else {
            text
        }
    }

    private func nonselectableMenuItem(_ menuItem: SidebarNonselectableMenuItem) -> some View {
        let text: Text
        let accessibilityLabel: Text
        let icon: String
        let isLink: Bool
        let action: () -> Void
        switch menuItem {
        case .connect:
            text = Text(L10n.Sidebar.Contacts.Connect.title)
            accessibilityLabel = Text("sidebar.contacts.connect.title", bundle: .module)
            icon = "person.badge.plus"
            isLink = false
            action = connectAction

        case .support:
            text = Text(L10n.Sidebar.Support.title)
            accessibilityLabel = Text("sidebar.support.description", tableName: "Accessibility", bundle: .module)
            icon = "questionmark.circle"
            isLink = true
            action = supportAction
        }

        return SidebarMenuItemView(
            icon: icon,
            iconSize: iconSize,
            isLink: isLink,
            title: { text.wireTextStyle(.body1) },
            accessibilityLabel: { accessibilityLabel },
            action: action
        )
    }

    @ViewBuilder
    private func selectableMenuItem(_ menuItem: SidebarSelectableMenuItem) -> some View {
        if menuItem == .folders {
            Framed { frame in
                makeSelectableMenuItem(menuItem, action: { foldersAction(frame) })
            }
        } else {
            makeSelectableMenuItem(menuItem, action: { selectedMenuItem = menuItem })
        }
    }

    private func makeSelectableMenuItem(
        _ menuItem: SidebarSelectableMenuItem,
        action: @escaping () -> Void
    ) -> some View {
        let text: Text
        let icon: String
        let accessibilityLabel: Text
        switch menuItem {
        case .all:
            text = Text(L10n.Sidebar.ConversationFilter.All.title)
            icon = "text.bubble"
            accessibilityLabel = Text(L10n.Sidebar.ConversationFilter.All.title)

        case .favorites:
            text = Text(L10n.Sidebar.ConversationFilter.Favorites.title)
            icon = "star"
            accessibilityLabel = Text(L10n.Sidebar.ConversationFilter.Favorites.title)

        case .groups:
            text = Text(L10n.Sidebar.ConversationFilter.Groups.title)
            icon = "person.3"
            accessibilityLabel = Text(L10n.Sidebar.ConversationFilter.Groups.title)

        case .oneOnOne:
            text = Text(L10n.Sidebar.ConversationFilter.OneOnOneConversations.title)
            icon = "person"
            accessibilityLabel = Text(
                "sidebar.conversation_filter.oneOnOneConversations.description",
                tableName: "Accessibility",
                bundle: .module
            )

        case .folders:
            text = Text(L10n.Sidebar.ConversationFilter.Folders.title)
            icon = "folder"
            accessibilityLabel = Text(L10n.Sidebar.ConversationFilter.Folders.title)

        case .archive:
            text = Text(L10n.Sidebar.ConversationFilter.Archived.title)
            icon = "archivebox"
            accessibilityLabel = Text(L10n.Sidebar.ConversationFilter.Archived.title)

        case .settings:
            text = Text(L10n.Sidebar.Settings.title)
            icon = "gearshape"
            accessibilityLabel = Text("sidebar.settings.description", tableName: "Accessibility", bundle: .module)
        }

        return SidebarMenuItemView(
            icon: icon,
            iconSize: iconSize,
            isLink: false,
            isHighlighted: selectedMenuItem == menuItem,
            title: { text.wireTextStyle(.body1) },
            accessibilityLabel: { accessibilityLabel },
            action: action
        )
    }

    public typealias AccountImageSource = SidebarAccountInfo.AccountImageSource
    public typealias Availability = SidebarAccountInfo.Availability
}

// MARK: - View Modifiers + Environment

extension View {
    func sidebarMenuHeaderForegroundColor(_ headerForegroundColor: Color) -> some View {
        modifier(SidebarMenuHeaderForegroundColorViewModifier(headerForegroundColor: headerForegroundColor))
    }

    func sidebarBackgroundColor(_ sidebarBackgroundColor: Color) -> some View {
        modifier(SidebarBackgroundColorViewModifier(sidebarBackgroundColor: sidebarBackgroundColor))
    }
}

private extension EnvironmentValues {
    var sidebarMenuHeaderForegroundColor: Color {
        get { self[SidebarMenuHeaderForegroundColorKey.self] }
        set { self[SidebarMenuHeaderForegroundColorKey.self] = newValue }
    }

    var sidebarBackgroundColor: Color {
        get { self[SidebarBackgroundColorKey.self] }
        set { self[SidebarBackgroundColorKey.self] = newValue }
    }
}

struct SidebarMenuHeaderForegroundColorViewModifier: ViewModifier {
    var headerForegroundColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarMenuHeaderForegroundColor, headerForegroundColor)
    }
}

private struct SidebarMenuHeaderForegroundColorKey: EnvironmentKey {
    static let defaultValue = Color.primary
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
