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

import WireLocators

struct SearchHeaderViewModel {

    struct DisplayState: Equatable {
        let clearButtonAccessibilityLabel: String
        let textFieldAccessibilityIdentifier: String
        let placeholder: String
        let clearButtonIsHidden: Bool
    }

    enum Route: Equatable {
        case updateQuery(String)
        case confirmSelection
        case none
    }

    func displayState(
        query: String = "",
        tokenCount: Int = 0
    ) -> DisplayState {
        DisplayState(
            clearButtonAccessibilityLabel: L10n.Accessibility.SearchView.ClearButton.description,
            textFieldAccessibilityIdentifier: Locators.SelectParticipantsPage.searchByNameOrUsername.rawValue,
            placeholder: L10n.Localizable.Peoplepicker.searchPlaceholder,
            clearButtonIsHidden: query.isEmpty && tokenCount == 0
        )
    }

    func routeForFilterTextChanged(_ text: String) -> Route {
        .updateQuery(text)
    }

    func routeForResetQuery(_ text: String) -> Route {
        .updateQuery(text)
    }

    func routeForConfirmSelection() -> Route {
        .confirmSelection
    }
}
