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

// TODO: snapshot tests
public struct SidebarView<AccountImageView>: View where AccountImageView: View {

    @Environment(\.sidebarBackgroundColor) private var sidebarBackgroundColor

    public var accountInfo: SidebarAccountInfo?
    @Binding public var conversationFilter: SidebarConversationFilter?
    private(set) var connectAction: () -> Void
    private(set) var settingsAction: () -> Void
    private(set) var supportAction: () -> Void
    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    @State private var iconSize: CGSize?

    public var body: some View {
        ZStack {
            // background color
            Rectangle()
                .foregroundStyle(sidebarBackgroundColor)
                .ignoresSafeArea()

            // content
            VStack(alignment: .leading, spacing: 0) {
                profileSwitcher

                let menuItemsScrollView = ScrollView(.vertical) { menuItems }
                if #available(iOS 16.4, *) {
                    menuItemsScrollView
                        .scrollBounceBehavior(.basedOnSize)
                } else {
                    menuItemsScrollView
                }

                Spacer()

                // bottom menu items
                SidebarMenuItem(icon: "gearshape", iconSize: iconSize) {
                    Text("sidebar.settings.title", bundle: .module)
                } action: {
                    settingsAction()
                }
                .padding(.horizontal, 16)

                SidebarMenuItem(icon: "questionmark.circle", iconSize: iconSize, isLink: true) {
                    Text("sidebar.support.title", bundle: .module)
                } action: {
                    supportAction()
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
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
            .padding(.horizontal, 24)
            .padding(.bottom)
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
            SidebarMenuItem(
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
    func label(_ iconSize: CGSize?, isActive: Bool, action: @escaping () -> Void) -> SidebarMenuItem {
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

        return SidebarMenuItem(
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
    if UIViewController().traitCollection.userInterfaceIdiom != .pad {
        HintViewController("For previewing please switch to iPad (iOS 17+)!")
    } else {
        SidebarPreview()
    }
}

@MainActor
func SidebarPreview() -> UIViewController {
    let splitViewController = UISplitViewController(style: .tripleColumn)
    let sidebarViewController = SidebarViewController { accountImage, availability in
        AnyView(MockAccountImageView(uiImage: accountImage, availability: availability))
    }
    sidebarViewController.accountInfo?.displayName = "Firstname Lastname"
    sidebarViewController.accountInfo?.username = "@username"
    splitViewController.setViewController(sidebarViewController, for: .primary)
    splitViewController.setViewController(EmptyViewController(), for: .supplementary)
    splitViewController.setViewController(EmptyViewController(), for: .secondary)
    splitViewController.setViewController(HintViewController("No sidebar visible!"), for: .compact)
    splitViewController.preferredSplitBehavior = .tile
    splitViewController.preferredDisplayMode = .twoBesideSecondary
    splitViewController.preferredPrimaryColumnWidth = 260
    splitViewController.preferredSupplementaryColumnWidth = 320
    splitViewController.view.backgroundColor = .init(white: 0.9, alpha: 1)

    return splitViewController
}

@MainActor private var conversationFilter: SidebarConversationFilter?

private struct MockAccountImageView: View {
    @State private(set) var uiImage: UIImage
    @State private(set) var availability: SidebarAccountInfo.Availability?
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(Color.brown)
            Circle()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.green)
        }
    }
}

private final class EmptyViewController: UIHostingController<AnyView> {
    convenience init() { self.init(rootView: AnyView(EmptyView())) }
    private struct EmptyView: View {
        var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemGray5))
                    .frame(height: 22)
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }.ignoresSafeArea()
        }
    }
}

private final class HintViewController: UIHostingController<Text> {
    convenience init(_ hint: String) {
        self.init(rootView: Text(verbatim: hint).font(.title2))
    }
}
