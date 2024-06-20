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

import UIKit

extension ConversationListViewController: UISearchControllerDelegate {

    // func willPresentSearchController(_ searchController: UISearchController) {
    //     print("342928u04 willPresentSearchController")
    // }

    // func didPresentSearchController(_ searchController: UISearchController) {
    //     print("342928u04 didPresentSearchController")
    // }

    // func willDismissSearchController(_ searchController: UISearchController) {
    //     print("342928u04 willDismissSearchController")
    // }

    // func didDismissSearchController(_ searchController: UISearchController) {
    //     print("342928u04 didDismissSearchController")
    // }

    // func presentSearchController(_ searchController: UISearchController) {
    //     print("342928u04 presentSearchController")
    // }

    @available(iOS 16.0, *)
    func searchController(_ searchController: UISearchController, willChangeTo newPlacement: UINavigationItem.SearchBarPlacement) {
        print("342928u04 willChangeTo newPlacement")
    }

    @available(iOS 16.0, *)
    func searchController(_ searchController: UISearchController, didChangeFrom previousPlacement: UINavigationItem.SearchBarPlacement) {
        print("342928u04 didChangeFrom previousPlacement")
    }
}

extension ConversationListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        print("342928u04 updateSearchResults text: \(searchController.searchBar.text ?? "<none>")")
    }

    @available(iOS 16.0, *)
    func updateSearchResults(for searchController: UISearchController, selecting searchSuggestion: any UISearchSuggestion) {
        print("342928u04 updateSearchResults selecting")
    }
}
