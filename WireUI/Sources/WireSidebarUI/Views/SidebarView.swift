//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public struct SidebarView<AccountImageView: View, LegalHoldIndicatorView: View>: View {

    @Environment(\.sidebarMenuHeaderForegroundColor) private var menuHeaderForegroundColor
    @Environment(\.sidebarBackgroundColor) private var backgroundViewColor

    public var accountInfo: SidebarAccountInfo?
    @Binding public var selectedMenuItem: SidebarSelectableMenuItem
    public var showUnreadFilters: Bool
    public var showMeetings: Bool
    public var showFiles: Bool

    private(set) var accountImageAction: () -> Void
    private(set) var foldersAction: (CGRect) -> Void
    private(set) var supportAction: () -> Void

    private(set) var accountImageView: SidebarViewController.AccountImageViewBuilder<AccountImageView>
    private(set) var legalHoldIndicatorView: () -> LegalHoldIndicatorView

    @State private var iconSize: CGSize?

    private typealias Strings = L10n.Localizable.Sidebar
    private typealias Labels = L10n.Accessibility.Sidebar

    public init(
        accountInfo: SidebarAccountInfo,
        selectedMenuItem: Binding<SidebarSelectableMenuItem>,
        showUnreadFilters: Bool,
        showMeetings: Bool,
        showFiles: Bool,
        accountImageAction: @escaping () -> Void,
        foldersAction: @escaping (_ buttonFrame: CGRect) -> Void,
        supportAction: @escaping () -> Void,
        accountImageView: @escaping SidebarViewController.AccountImageViewBuilder<AccountImageView>,
        legalHoldIndicatorView: @escaping () -> LegalHoldIndicatorView
    ) {
        self.accountInfo = accountInfo
        _selectedMenuItem = selectedMenuItem
        self.showUnreadFilters = showUnreadFilters
        self.showMeetings = showMeetings
        self.showFiles = showFiles
        self.accountImageAction = accountImageAction
        self.foldersAction = foldersAction
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
                menuItemsScrollView
                    .scrollBounceBehavior(.basedOnSize)

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
                accountImageView: { accountImageView(
                    accountInfo.accountImageSource,
                    accountInfo.availability,
                    accountInfo.showNotificationsBadge
                ) },
                legalHoldIndicatorView: { legalHoldIndicatorView() }
            )
        }
    }

    @ViewBuilder private var scrollableMenuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItemHeader(Strings.ConversationFilter.title, addTopPadding: false)

            // Core filters
            selectableMenuItem(.all)
            selectableMenuItem(.favorites)
            selectableMenuItem(.groups)
            selectableMenuItem(.channels)
            selectableMenuItem(.oneOnOne)

            // Conditional unread filters
            if showUnreadFilters {
                selectableMenuItem(.unread)
                selectableMenuItem(.mentions)
                selectableMenuItem(.replies)
                selectableMenuItem(.drafts)
            }

            // Additional filters
            selectableMenuItem(.folders)
            selectableMenuItem(.archive)

            // Meetings
            if showMeetings {
                menuItemHeader(Strings.Meetings.title, addTopPadding: false)
                selectableMenuItem(.meetings)
            }

            // Files
            if showFiles {
                menuItemHeader(Strings.Files.title, addTopPadding: false)
                selectableMenuItem(.files)
            }
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

        case .support:
            text = Text(Strings.Support.title)
            accessibilityLabel = Text(Labels.Support.description)
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
        var iconHighlighted: String?
        let accessibilityLabel: Text
        switch menuItem {
        case .all:
            text = Text(Strings.ConversationFilter.All.title)
            icon = "text.bubble"
            accessibilityLabel = Text(Strings.ConversationFilter.All.title)

        case .favorites:
            text = Text(Strings.ConversationFilter.Favorites.title)
            icon = "star"
            accessibilityLabel = Text(Strings.ConversationFilter.Favorites.title)

        case .groups:
            text = Text(Strings.ConversationFilter.Groups.title)
            icon = "person.3"
            accessibilityLabel = Text(Strings.ConversationFilter.Groups.title)

        case .channels:
            text = Text(Strings.ConversationFilter.Channels.title)
            icon = "number"
            iconHighlighted = "number"
            accessibilityLabel = Text(Strings.ConversationFilter.Channels.title)

        case .oneOnOne:
            text = Text(Strings.ConversationFilter.OneOnOneConversations.title)
            icon = "person"
            accessibilityLabel = Text(Labels.ConversationFilter.OneOnOneConversations.description)

        case .unread:
            text = Text(Strings.ConversationFilter.Unread.title)
            icon = "1.square"
            iconHighlighted = "1.square.fill"
            accessibilityLabel = Text(Labels.ConversationFilter.Unread.description)

        case .mentions:
            text = Text(Strings.ConversationFilter.Mentions.title)
            icon = "at"
            iconHighlighted = "at"
            accessibilityLabel = Text(Labels.ConversationFilter.Mentions.description)

        case .replies:
            text = Text(Strings.ConversationFilter.Replies.title)
            icon = "arrowshape.turn.up.left"
            iconHighlighted = "arrowshape.turn.up.left"
            accessibilityLabel = Text(Labels.ConversationFilter.Replies.description)

        case .drafts:
            text = Text(Strings.ConversationFilter.Drafts.title)
            icon = "pencil.and.ellipsis.rectangle"
            iconHighlighted = "pencil.and.ellipsis.rectangle.fill"
            accessibilityLabel = Text(Labels.ConversationFilter.Drafts.description)

        case .folders:
            text = Text(Strings.ConversationFilter.Folders.title)
            icon = "folder"
            accessibilityLabel = Text(Strings.ConversationFilter.Folders.title)

        case .archive:
            text = Text(Strings.ConversationFilter.Archived.title)
            icon = "archivebox"
            accessibilityLabel = Text(Strings.ConversationFilter.Archived.title)

        case .meetings:
            text = Text(Strings.Meetings.AllMeetings.title)
            icon = "video"
            accessibilityLabel = Text(Strings.Meetings.AllMeetings.title)

        case .files:
            text = Text(Strings.Files.AllFiles.title)
            icon = "rectangle.stack"
            accessibilityLabel = Text(Strings.Files.AllFiles.title)

        case .settings:
            text = Text(Strings.Settings.title)
            icon = "gearshape"
            accessibilityLabel = Text(Labels.Settings.description)
        }

        return SidebarMenuItemView(
            icon: icon,
            iconHighlighted: iconHighlighted,
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
