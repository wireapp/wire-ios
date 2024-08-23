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

    let accountImage: UIImage
    let isTeamAccount: Bool
    let availability: Availability?
    let displayName: String
    let username: String

    var body: some View {
        ZStack {

            // background color
            Rectangle()
                .foregroundStyle(Color(ColorTheme.Backgrounds.background))
                .ignoresSafeArea()

            // content
            VStack(alignment: .leading) {

                SidebarProfileSwitcherView(displayName, username) {
                    AccountImageViewRepresentable(accountImage, isTeamAccount, availability)
                }
                .padding(.horizontal, 24)

                ScrollView {

                    Text("Conversations")
                        .background(Color.green)
                    Text("Favorites")
                    Text("Groups")
                    Text("1:1 Conversations")
                    Text("Archive")

                    Text("Contacts")
                    Text("Connect")
                }
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                Spacer()
                Text("Settings")
                Text("Support")
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.4))
        }
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

        let viewModel = SidebarViewModel()
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
