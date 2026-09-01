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
import UIKit

extension FilesFilterBy {
    /// Disables `UISearchController.hidesNavigationBarDuringPresentation` so activating the search
    /// field (via `.searchable`) does not hide the navigation bar's title and toolbar items.
    struct SearchControllerNavigationBarVisibility: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            UIViewController()
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            DispatchQueue.main.async {
                searchController(from: uiViewController)?.hidesNavigationBarDuringPresentation = false
            }
        }

        private func searchController(from viewController: UIViewController) -> UISearchController? {
            var current: UIViewController? = viewController
            while let candidate = current {
                if let searchController = candidate.navigationItem.searchController {
                    return searchController
                }
                current = candidate.parent
            }
            return nil
        }
    }
}
