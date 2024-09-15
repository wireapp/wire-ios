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
import WireDesign // TODO: can the dependency be removed?

public extension UIViewController {

    func setupNavigationBarTitle(_ title: String) {
        navigationItem.title = title

        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: SemanticColors.Label.textDefault,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        navigationController?.navigationBar.titleTextAttributes = titleTextAttributes

        navigationItem.titleView?.isAccessibilityElement = true
        navigationItem.titleView?.accessibilityTraits = .header
        navigationItem.titleView?.accessibilityLabel = navigationItem.title

        navigationItem.titleView?.showsLargeContentViewer = true
        navigationItem.titleView?.largeContentTitle = navigationItem.title
    }
}

// MARK: - Previews

struct ViewControllerPreview: UIViewControllerRepresentable {
    let title: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white

        viewController.setupNavigationBarTitle(title)

        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview("Preview Title") {
    ViewControllerPreview(title: "Preview Title")
}
