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

struct SidebarView: View {

    @EnvironmentObject var info: SidebarData

    @State private var iconSize: CGSize?

    var body: some View {
        ZStack {

            // background color
            Rectangle()
                .foregroundStyle(Color(ColorTheme.Backgrounds.background))
                .ignoresSafeArea()

            // content
            VStack(alignment: .leading, spacing: 0) {

                profileSwitcher
                    .padding(.bottom, 4)
                scrollDeactivatableMenuItems(isScrollDisabled: false) // TODO: pass value
                    .background(Color.yellow)
                Spacer()

                // bottom menu items
                SidebarMenuItem(icon: "gearshape", iconSize: iconSize) {
                    Text(String("Settings".reversed()))
                } action: {
                    print("settings")
                }
                .padding(.horizontal, 16)

                SidebarMenuItem(icon: "questionmark.circle", iconSize: iconSize, isLink: true) {
                    Text(String("Support".reversed()))
                } action: {
                    print("support")
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .onPreferenceChange(SidebarMenuItemIconSizeKey.self) { newIconSize in
            guard var iconSize else { return iconSize = newIconSize }
            iconSize.width = max(iconSize.width, newIconSize.width)
            iconSize.height = max(iconSize.height, newIconSize.height)
            self.iconSize = iconSize
        }
    }

    @ViewBuilder
    private var profileSwitcher: some View {

        if let accountInfo = info.accountInfo {
            SidebarProfileSwitcherView(accountInfo.displayName, accountInfo.username) {
                AccountImageViewRepresentable(accountInfo.accountImage, accountInfo.isTeamAccount, info.availability)
            }
            .padding(.horizontal, 24)
            .padding(.bottom)
        }
    }

    /// Workaround, remove once the deployment target is equal or above iOS 16.
    @ViewBuilder
    private func scrollDeactivatableMenuItems(isScrollDisabled: Bool) -> some View {

        // TODO: finish implementation! (preference key)
        if #available(iOS 16.0, *) {
            ScrollView(.vertical) {
                menuItems
            }.scrollDisabled(isScrollDisabled)

        } else if !isScrollDisabled {
            ScrollView(.vertical) {
                menuItems
            }
        } else {
            menuItems
        }
    }

    @ViewBuilder
    private var menuItems: some View {

        VStack(alignment: .leading) {
            // TODO: where to get strings from?
            Text(String("Conversations".reversed()))
                .font(.textStyle(.h2))
                .padding(.horizontal, 8)
            ForEach([SidebarData.ConversationFilter?.none] + SidebarData.ConversationFilter.allCases, id: \.self) { conversationFilter in
                conversationFilter.label(iconSize, isActive: info.conversationFilter == conversationFilter)
            }

            Text(String("Contacts".reversed()))
                .font(.textStyle(.h2))
                .padding(.horizontal, 8)
            SidebarMenuItem(
                icon: "person.badge.plus",
                iconSize: iconSize
            ) {
                Text(String("Connect".reversed()))
            } action: {
                //
            }
        }
        .padding(.horizontal, 16)
        .background(Color.brown)
    }
}

// MARK: - SidebarData.ConversationFilter + label

extension Optional where Wrapped == SidebarData.ConversationFilter {

    func label(_ iconSize: CGSize?, isActive: Bool) -> SidebarMenuItem {

        let text: Text
        let icon: String
        let action: () -> Void = {}

        switch self {
        case .none:
            text = Text(String("All".reversed()))
            icon = "text.bubble"
        case .favorites:
            text = Text(String("Favorites".reversed()))
            icon = "star"
        case .groups:
            text = Text(String("Groups".reversed()))
            icon = "person.3"
        case .oneOnOne:
            text = Text(String("1:1 Conversations".reversed()))
            icon = "person"
        case .archived:
            text = Text(String("Archive".reversed()))
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
    {
        let splitViewController = UISplitViewController(style: .tripleColumn)
        if splitViewController.traitCollection.userInterfaceIdiom != .pad {
            return HintViewController("For previewing please switch to iPad (iOS 17+)!")
        }

        let viewModel = SidebarViewModel(
            accountInfo: .init(
                displayName: "Firstname Lastname",
                username: "@username",
                accountImage: .from(solidColor: .brown),
                isTeamAccount: false
            ),
            availability: .available,
            conversationFilter: .none
        )
        splitViewController.setViewController(SidebarViewController(viewModel: viewModel), for: .primary)
        splitViewController.setViewController(EmptyViewController(), for: .supplementary)
        splitViewController.setViewController(EmptyViewController(), for: .secondary)
        splitViewController.setViewController(HintViewController("No sidebar visible!"), for: .compact)
        splitViewController.preferredSplitBehavior = .tile
        splitViewController.preferredDisplayMode = .twoBesideSecondary
        splitViewController.preferredPrimaryColumnWidth = 260
        splitViewController.preferredSupplementaryColumnWidth = 320
        splitViewController.view.backgroundColor = ColorTheme.Backgrounds.background

        return splitViewController
    }()
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

private extension UIImage {

    // TODO: look for all copies and move the code into WireUtilities or WireSystem
    static func from(solidColor color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
