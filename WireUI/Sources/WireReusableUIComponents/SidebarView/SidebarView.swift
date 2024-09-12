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
import WireFoundation

public struct SidebarView<AccountImageView>: View where AccountImageView: View {

    public var accountInfo: SidebarAccountInfo?
    @Binding public var conversationFilter: SidebarConversationFilter?
    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    @State private var iconSize: CGSize?

    public var body: some View {
        ZStack {
            // background color
            Rectangle()
                .foregroundStyle(Color(ColorTheme.Backgrounds.background))
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
                    print("settings")
                }
                .padding(.horizontal, 16)

                SidebarMenuItem(icon: "questionmark.circle", iconSize: iconSize, isLink: true) {
                    Text("sidebar.support.title", bundle: .module)
                } action: {
                    print("support")
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
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

    @ViewBuilder
    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("sidebar.conversation_filter.title", bundle: .module)
                .font(.textStyle(.h2))
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            ForEach([SidebarConversationFilter?.none] + SidebarConversationFilter.allCases, id: \.self) { conversationFilter in
                conversationFilter.label(iconSize, isActive: self.conversationFilter == conversationFilter) {
                    self.conversationFilter = conversationFilter
                }
            }

            Text("sidebar.contacts.title", bundle: .module)
                .font(.textStyle(.h2))
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, 12)
            SidebarMenuItem(
                icon: "person.badge.plus",
                iconSize: iconSize
            ) {
                Text("sidebar.contacts.connect.title", bundle: .module)
            } action: {
                // TODO: implement
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

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    TempX()
}

private final class TempX: UIHostingController<SidebarView<MockAccountImageView>> {
    var accountInfo: SidebarAccountInfo? {
        get { rootView.accountInfo }
        set { rootView.accountInfo = newValue }
    }
    var conversationFilter: SidebarConversationFilter?
    convenience init() {
        var self_: TempX?
        self.init(
            rootView: .init(
                accountInfo: .init(),
                conversationFilter: .init { self_!.conversationFilter } set: { self_!.conversationFilter = $0 },
                accountImageView: MockAccountImageView.init
            )
        )
        self_ = self
    }
}

//struct Temp: View {
//    @State var accountInfo = SidebarAccountInfo()
//    @State var conversationFilter: SidebarConversationFilter?
//    var body: some View {
//        SidebarView(
//            accountInfo: accountInfo,
//            conversationFilter: $conversationFilter,
//            accountImageView: MockAccountImageView.init(uiImage:availability:)
//        )
//    }
//}
//
//@available(iOS 17, *)
//#Preview {
//    Temp()
//}

@available(iOS 17, *)
#Preview {
    {
        let splitViewController = UISplitViewController(style: .tripleColumn)
        if splitViewController.traitCollection.userInterfaceIdiom != .pad {
            return HintViewController("For previewing please switch to iPad (iOS 17+)!")
        }

        //@State var conversationFilter: SidebarConversationFilter?
        var conversationFilter: SidebarConversationFilter?
        var sidebarView = SidebarView(
            accountInfo: .init(),
            // conversationFilter: $conversationFilter,
            conversationFilter: .init { conversationFilter } set: { conversationFilter = $0 },
            accountImageView: MockAccountImageView.init(uiImage:availability:)
        )
        sidebarView.accountInfo?.displayName = "Firstname Lastname"
        sidebarView.accountInfo?.username = "@username"
        let sidebarViewController = UIHostingController(rootView: sidebarView)
        splitViewController.setViewController(sidebarViewController, for: .primary)
        splitViewController.setViewController(EmptyViewController(), for: .supplementary)
        splitViewController.setViewController(EmptyViewController(), for: .secondary)
        splitViewController.setViewController(HintViewController("No sidebar visible!"), for: .compact)
        splitViewController.preferredSplitBehavior = .tile
        splitViewController.preferredDisplayMode = .twoBesideSecondary
        splitViewController.preferredPrimaryColumnWidth = 260
        splitViewController.preferredSupplementaryColumnWidth = 320
        splitViewController.view.backgroundColor = ColorTheme.Backgrounds.background

        return splitViewController
    }() as UIViewController
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
        let sidebarBackground = Color(ColorTheme.Backgrounds.background)
        let defaultBackground = Color(ColorTheme.Backgrounds.backgroundVariant)
        var body: some View {
            VStack {
                Rectangle().foregroundStyle(sidebarBackground).frame(height: 22)
                Rectangle().foregroundStyle(defaultBackground)
            }.ignoresSafeArea()
        }
    }
}

private final class HintViewController: UIHostingController<Text> {
    convenience init(_ hint: String) {
        self.init(rootView: Text(verbatim: hint).font(.title2))
    }
}
