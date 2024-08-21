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

@MainActor
public func SidebarViewController() -> UIViewController {
    UIHostingController(rootView: SidebarView())
}

struct SidebarView: View {

    var body: some View {
        ZStack {
            // background color
            Rectangle()
                .foregroundStyle(Color(ColorTheme.Backgrounds.background))
                .ignoresSafeArea()
            // content
            VStack {
                userInfo
                Spacer()
            }.background(Color.red)
        }
    }

    private var userInfo: some View {
        Text("TODO").multilineTextAlignment(.leading)
    }
}

public final class SidebarViewController_: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.Backgrounds.background

        let label = UILabel()
        label.text = "Sidebar"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let splitViewController = UISplitViewController(style: .tripleColumn)
        if splitViewController.traitCollection.userInterfaceIdiom != .pad {
            return HintViewController("Please switch to iPad (iOS 17+)!")
        }

        splitViewController.setViewController(SidebarViewController(), for: .primary)
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
