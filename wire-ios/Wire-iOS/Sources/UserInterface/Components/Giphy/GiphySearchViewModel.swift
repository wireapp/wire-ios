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

import Foundation
import Ziphy

struct GiphySearchViewModel {

    struct DisplayState {
        let ziphs: [Ziph]
        let isEmptyStateHidden: Bool
        let isLoading: Bool
    }

    enum Action {
        case searchTextChanged(String)
        case searchRequested
        case searchSucceeded([Ziph])
        case searchFailed
    }

    enum Effect {
        case performSearch(SearchRequest)
        case none
    }

    enum SearchRequest {
        case trending
        case query(String)
    }

    private(set) var searchTerm: String
    private(set) var displayState: DisplayState

    init(searchTerm: String) {
        self.searchTerm = searchTerm
        self.displayState = DisplayState(
            ziphs: [],
            isEmptyStateHidden: true,
            isLoading: false
        )
    }

    mutating func effect(for action: Action) -> Effect {
        switch action {
        case let .searchTextChanged(searchTerm):
            self.searchTerm = searchTerm
            return .none

        case .searchRequested:
            displayState = DisplayState(
                ziphs: displayState.ziphs,
                isEmptyStateHidden: displayState.isEmptyStateHidden,
                isLoading: true
            )

            return .performSearch(searchRequest)

        case let .searchSucceeded(ziphs):
            displayState = DisplayState(
                ziphs: ziphs,
                isEmptyStateHidden: !ziphs.isEmpty,
                isLoading: false
            )

            return .none

        case .searchFailed:
            displayState = DisplayState(
                ziphs: [],
                isEmptyStateHidden: false,
                isLoading: false
            )

            return .none
        }
    }

    mutating func appendSearchResults(_ ziphs: [Ziph]) {
        let updatedZiphs = displayState.ziphs + ziphs
        displayState = DisplayState(
            ziphs: updatedZiphs,
            isEmptyStateHidden: !updatedZiphs.isEmpty,
            isLoading: displayState.isLoading
        )
    }

    private var searchRequest: SearchRequest {
        searchTerm.isEmpty ? .trending : .query(searchTerm)
    }

}
