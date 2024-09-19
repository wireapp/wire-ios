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

// TODO: remove commented code
// private let sidebarBackgroundColor: UIColor = .init(white: 0.9, alpha: 1) // ColorTheme.Backgrounds.background

public struct SidebarView<AccountImageView>: View where AccountImageView: View {

    @Environment(\.sidebarBackgroundColor) private var sidebarBackgroundColor

    public var accountInfo: SidebarAccountInfo?
    @Binding public var conversationFilter: SidebarConversationFilter?

    private(set) var accountImageAction: () -> Void
    private(set) var connectAction: () -> Void
    private(set) var settingsAction: () -> Void
    private(set) var supportAction: () -> Void

    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    @State private var iconSize: CGSize?

    public init(
        accountInfo: SidebarAccountInfo,
        conversationFilter: Binding<SidebarConversationFilter?>,
        accountImageAction: @escaping () -> Void,
        connectAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void,
        supportAction: @escaping () -> Void,
        accountImageView: @escaping (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AccountImageView
    ) {
        self.accountInfo = accountInfo
        _conversationFilter = conversationFilter
        self.accountImageAction = accountImageAction
        self.connectAction = connectAction
        self.settingsAction = settingsAction
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
                profileSwitcher
                    .onTapGesture(perform: accountImageAction)
                    .padding(.horizontal, 24)
                    .padding(.vertical)

                let menuItemsScrollView = ScrollView(.vertical) { menuItems }
                if #available(iOS 16.4, *) {
                    menuItemsScrollView
                        .scrollBounceBehavior(.basedOnSize)
                } else {
                    menuItemsScrollView
                }

                // bottom menu items
                SidebarMenuItemView(icon: "gearshape", iconSize: iconSize) {
                    Text("sidebar.settings.title", bundle: .module)
                } action: {
                    settingsAction()
                }
                .padding(.horizontal, 16)

                SidebarMenuItemView(icon: "questionmark.circle", iconSize: iconSize, isLink: true) {
                    Text("sidebar.support.title", bundle: .module)
                } action: {
                    supportAction()
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
    private var profileSwitcher: some View {
        if let accountInfo {
            SidebarProfileSwitcherView(
                displayName: accountInfo.displayName,
                username: accountInfo.username,
                accountImageView: { accountImageView(accountInfo.accountImage, accountInfo.availability) }
            )
        }
    }

    @ViewBuilder @MainActor
    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("sidebar.conversation_filter.title", bundle: .module)
                .wireTextStyle(.h2)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            ForEach([SidebarConversationFilter?.none] + SidebarConversationFilter.allCases, id: \.self) { conversationFilter in
                conversationFilter.label(iconSize, isActive: self.conversationFilter == conversationFilter) {
                    self.conversationFilter = conversationFilter
                }
            }

            Text("sidebar.contacts.title", bundle: .module)
                .wireTextStyle(.h2)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, 12)
            SidebarMenuItemView(
                icon: "person.badge.plus",
                iconSize: iconSize
            ) {
                Text("sidebar.contacts.connect.title", bundle: .module)
            } action: {
                connectAction()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - SidebarData.ConversationFilter + label

private extension SidebarConversationFilter? {

    @MainActor
    func label(_ iconSize: CGSize?, isActive: Bool, action: @escaping () -> Void) -> SidebarMenuItemView {
        let text: Text
        let icon: String

        switch self {
        case .none:
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

        case .archived:
            text = Text("sidebar.conversation_filter.archived.title", bundle: .module)
            icon = "archivebox"
        }

        return SidebarMenuItemView(
            icon: icon,
            iconSize: iconSize,
            isLink: false,
            isHighlighted: isActive,
            title: { text },
            action: action
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
    SidebarPreviewHelper()
}

@MainActor
private func SidebarPreviewHelper() -> UIViewController {
    if UIViewController().traitCollection.userInterfaceIdiom != .pad {
        HintViewController("For previewing please switch to iPad (iOS 17+)!")
    } else {
        SidebarPreview()
    }
}
