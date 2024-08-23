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

    var body: some View {
        ZStack {

            // background color
            Rectangle()
                .foregroundStyle(Color(ColorTheme.Backgrounds.background))
                .ignoresSafeArea()

            // content
            VStack(alignment: .leading, spacing: 0) {

                profileSwitcher
                scrollDeactivatableMenuItems(isScrollDisabled: false) // TODO: pass value
                    .background(Color.yellow)
                Spacer()

                // bottom menu items
                SidebarMenuItem(icon: "gearshape") {
                    Text(String("Settings".reversed()))
                } action: {
                    print("settings")
                }
                .padding(.horizontal, 16)

                SidebarMenuItem(icon: "questionmark.circle", isLink: true) {
                    Text(String("Support".reversed()))
                } action: {
                    print("support")
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.4))
            .padding(.bottom)
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
            ForEach([SidebarData.ConversationFilter?.none] + SidebarData.ConversationFilter.allCases, id: \.self) { conversationFilter in
                conversationFilter.label(isActive: info.conversationFilter == conversationFilter)
            }

            Text(String("Contacts".reversed()))
                .font(.textStyle(.h2))
            Button(action: {}, label: {
                Label { Text(String("Connect".reversed())) } icon: { Image(systemName: "person.badge.plus") }
            })
        }
        .padding(.horizontal, 8 + 16)
        .background(Color.brown)
    }
}

// SidebarData.ConversationFilter + label

extension Optional where Wrapped == SidebarData.ConversationFilter {

    func label(isActive: Bool) -> Label<Text, Image> {
        switch self {
        case .none:
            Label { Text(String("All".reversed())) } icon: { Image(systemName: isActive ? "text.bubble.fill" : "text.bubble") }
        case .favorites:
            Label { Text(String("Favorites".reversed())) } icon: { Image(systemName: isActive ? "star.fill" : "star") }
        case .groups:
            Label { Text(String("Groups".reversed())) } icon: { Image(systemName: isActive ? "person.3.fill" : "person.3") }
        case .oneOnOne:
            Label { Text(String("1:1 Conversations".reversed())) } icon: { Image(systemName: isActive ? "person.fill" : "person") }
        case .archived:
            Label { Text(String("Archive".reversed())) } icon: { Image(systemName: isActive ? "archivebox.fill" : "archivebox") }
        }

        //SidebarMenuItem()
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
