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

final class DoubleColumnContainerViewController: UIViewController {

    typealias Primary = UIViewController
    typealias Secondary = UIViewController

    var primary: Primary? {
        get { primaryNavigationController.viewControllers.first }
        set { primaryNavigationController.viewControllers = [newValue].compactMap { $0 } }
    }

    var secondary: Secondary? {
        get { secondaryNavigationController.viewControllers.first }
        set { secondaryNavigationController.viewControllers = [newValue].compactMap { $0 } }
    }

    var primaryColumnWidth: CGFloat = 100 {
        didSet { primaryColumnWidthConstraint?.constant = primaryColumnWidth }
    }

    private let primaryNavigationController = UINavigationController()
    private let secondaryNavigationController = UINavigationController()
    private var primaryColumnWidthConstraint: NSLayoutConstraint?

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildren()
    }

    private func setupChildren() {
        addChild(primaryNavigationController)
        primaryNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(primaryNavigationController.view)
        primaryNavigationController.didMove(toParent: self)

        addChild(secondaryNavigationController)
        secondaryNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(secondaryNavigationController.view)
        secondaryNavigationController.didMove(toParent: self)

        let constraints = [
            primaryNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            primaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: primaryNavigationController.view.bottomAnchor),
            primaryNavigationController.view.widthAnchor.constraint(equalToConstant: primaryColumnWidth),

            secondaryNavigationController.view.leadingAnchor.constraint(equalTo: primaryNavigationController.view.trailingAnchor),
            secondaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: secondaryNavigationController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondaryNavigationController.view.bottomAnchor)
        ]
        primaryColumnWidthConstraint = constraints[3]
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let sidebar = PreviewSidebarViewController("sidebar")
        let container = DoubleColumnContainerViewController()
        container.primary = UIHostingController(rootView: LabelView(content: "Conversations", backgroundColor: .yellow))
        container.primary?.navigationItem.title = "Primary"
        container.secondary = UIHostingController(rootView: LabelView(content: "Conversation", backgroundColor: .green))
        container.secondary?.navigationItem.title = "Secondary"
        container.primaryColumnWidth = 400

        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.preferredSplitBehavior = .overlay
        splitViewController.preferredPrimaryColumnWidth = 180
        splitViewController.setViewController(sidebar, for: .primary)
        splitViewController.setViewController(container, for: .secondary)
        return splitViewController
    }()
}
