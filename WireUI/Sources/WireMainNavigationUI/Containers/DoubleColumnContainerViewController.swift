//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

    /// When true, the primary column fills the entire container and the secondary
    /// column and border are hidden. Use for full-bleed content (e.g. files,
    /// meetings) instead of inflating `primaryColumnWidth`.
    ///
    /// Why: previously full-bleed screens set `primaryColumnWidth` to the current
    /// screen width, which is captured once at install time. On rotation the
    /// container grew but the primary constraint didn't, exposing a strip of the
    /// secondary column (i.e. whatever conversation was last displayed). Toggling
    /// the layout instead of the width sidesteps that entirely — no captured
    /// value can become stale on rotation.
    var isSecondaryHidden: Bool = false {
        didSet {
            guard isSecondaryHidden != oldValue else { return }
            updateColumnConstraints()
        }
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
    // Two-column layout: primary has a fixed width and the secondary fills the rest,
    // pinned to primary's trailing edge via the border.
    private var primaryTrailingToBorderConstraint: NSLayoutConstraint?
    // Single-column layout: primary stretches to the container's trailing edge,
    // leaving no room for the border or the secondary (both are also hidden).
    private var primaryTrailingToContainerConstraint: NSLayoutConstraint?

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

        borderWidthConstraint = borderView.widthAnchor.constraint(equalToConstant: borderWidth)
        primaryColumnWidthConstraint = primaryNavigationController.view.widthAnchor
            .constraint(equalToConstant: primaryColumnWidth)
        primaryTrailingToBorderConstraint = borderView.leadingAnchor
            .constraint(equalTo: primaryNavigationController.view.trailingAnchor)
        primaryTrailingToContainerConstraint = primaryNavigationController.view.trailingAnchor
            .constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: view.topAnchor),
            borderWidthConstraint!,
            view.bottomAnchor.constraint(equalTo: borderView.bottomAnchor),

            primaryNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            primaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: primaryNavigationController.view.bottomAnchor),

            secondaryNavigationController.view.leadingAnchor.constraint(equalTo: borderView.trailingAnchor),
            secondaryNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: secondaryNavigationController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondaryNavigationController.view.bottomAnchor)
        ])
        updateColumnConstraints()
    }

    /// Switches between the two- and single-column layouts by activating one of
    /// the two mutually exclusive trailing constraints on the primary column,
    /// then hiding (rather than removing) the secondary column and border so
    /// their state is preserved across the toggle.
    private func updateColumnConstraints() {
        primaryColumnWidthConstraint?.isActive = !isSecondaryHidden
        primaryTrailingToBorderConstraint?.isActive = !isSecondaryHidden
        primaryTrailingToContainerConstraint?.isActive = isSecondaryHidden
        borderView.isHidden = isSecondaryHidden
        secondaryNavigationController.view.isHidden = isSecondaryHidden
        view.layoutIfNeeded()
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
