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

/// The split view behavior which is required for the app is not achievable with the `tripleColumn` style
/// of `UISplitViewController`. Therefore we use the `doubleColumn` style and combine the
/// supplementary and secondary column in this custom conatiner view controller.
final class DoubleColumnContainerViewController: UIViewController {

    // MARK: Internal Properties

    let primaryNavigationController = UINavigationController()
    let secondaryNavigationController = UINavigationController()

    var primaryColumnWidth: CGFloat = 100 {
        didSet { primaryColumnWidthConstraint?.constant = primaryColumnWidth }
    }

    var borderColor: UIColor = .gray {
        didSet { borderView.backgroundColor = borderColor }
    }

    var borderWidth: CGFloat = 0.5 {
        didSet { borderWidthConstraint?.constant = primaryColumnWidth }
    }

    // MARK: - Private Properties

    private let borderView = UIView()
    private var borderWidthConstraint: NSLayoutConstraint?
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

        borderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(borderView)
        borderView.backgroundColor = borderColor

        let constraints = [
            borderView.leadingAnchor.constraint(equalTo: primaryNavigationController.view.trailingAnchor),
            borderView.topAnchor.constraint(equalTo: view.topAnchor),
            borderView.widthAnchor.constraint(equalToConstant: borderWidth),
            view.bottomAnchor.constraint(equalTo: borderView.bottomAnchor),

            primaryNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            primaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: primaryNavigationController.view.bottomAnchor),
            primaryNavigationController.view.widthAnchor.constraint(equalToConstant: primaryColumnWidth),

            secondaryNavigationController.view.leadingAnchor.constraint(equalTo: borderView.trailingAnchor),
            secondaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: secondaryNavigationController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondaryNavigationController.view.bottomAnchor)
        ]
        borderWidthConstraint = constraints[2]
        primaryColumnWidthConstraint = constraints[7]
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let sidebar = PreviewSidebarViewController("sidebar")
        let primary = UIHostingController(rootView: LabelView(content: "Conversations", backgroundColor: .yellow))
        primary.navigationItem.title = "Primary"
        let secondary = UIHostingController(rootView: LabelView(content: "Conversation", backgroundColor: .green))
        secondary.navigationItem.title = "Secondary"

        let container = DoubleColumnContainerViewController()
        container.primaryNavigationController.viewControllers = [primary]
        container.secondaryNavigationController.viewControllers = [secondary]
        container.primaryColumnWidth = 400
        container.borderColor = .red
        container.borderWidth = 1

        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.preferredSplitBehavior = .overlay
        splitViewController.preferredPrimaryColumnWidth = 180
        splitViewController.setViewController(sidebar, for: .primary)
        splitViewController.setViewController(container, for: .secondary)
        return splitViewController
    }()
}
