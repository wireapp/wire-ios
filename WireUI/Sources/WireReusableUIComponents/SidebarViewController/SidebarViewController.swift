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

public final class SidebarViewController: UIViewController {

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
            return HintViewController("Please switch to iPad!")
        }

        splitViewController.setViewController(.init(), for: .primary)
        splitViewController.setViewController(EmptyViewController(), for: .supplementary)
        splitViewController.setViewController(EmptyViewController(), for: .secondary)
        splitViewController.setViewController(HintViewController("No sidebar visible!"), for: .compact)

        return splitViewController
    }()
}

private final class EmptyViewController: UIViewController {

    private var fakeSidebarHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFakeSidebarBackground()
        updateFakeSidebarBackgroundSize()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        updateFakeSidebarBackgroundSize()
    }

    private func setupFakeSidebarBackground() {
        let fakeSideBarBackground = UIView()
        fakeSideBarBackground.backgroundColor = ColorTheme.Backgrounds.backgroundVariant
        fakeSideBarBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fakeSideBarBackground)
        fakeSidebarHeightConstraint = fakeSideBarBackground.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            fakeSideBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fakeSideBarBackground.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: fakeSideBarBackground.trailingAnchor),
            fakeSidebarHeightConstraint
        ])
    }

    private func updateFakeSidebarBackgroundSize() {
        fakeSidebarHeightConstraint.constant = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
}

/// Hint for the user to switch to iPad previews.
private final class HintViewController: UIViewController {

    private let text: String
    fileprivate init(_ text: String) { self.text = text; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        view = label
    }
}
