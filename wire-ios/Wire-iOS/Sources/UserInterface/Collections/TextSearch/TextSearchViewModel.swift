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
import WireSyncEngine

struct TextSearchRowModel {
    let message: ZMConversationMessage
    let queries: [String]
}

struct TextSearchViewModel {

    enum Effect: Equatable {
        case cancelSearch
        case scheduleSearch
    }

    enum Route {
        case showInConversation(ZMConversationMessage)
        case ignore
    }

    struct ViewState: Equatable {
        let isResultsViewHidden: Bool
        let isTableViewHidden: Bool
        let isNoResultsViewHidden: Bool
        let isLoading: Bool
    }

    private(set) var query = ""
    private(set) var results: [ZMConversationMessage] = []
    private(set) var isLoading = false

    var searchPlaceholder: String {
        L10n.Localizable.Collections.Search.Field.placeholder
    }

    var noResultsText: String {
        L10n.Localizable.Collections.Search.noItems
    }

    var noResultsAccessibilityLabel: String {
        L10n.Accessibility.ConversationSearch.EmptyResult.description
    }

    var numberOfRows: Int {
        results.count
    }

    var viewState: ViewState {
        let noResults = results.isEmpty
        let validQuery = TextSearchQuery.isValid(query: query)

        return ViewState(
            isResultsViewHidden: query.isEmpty,
            isTableViewHidden: noResults || !validQuery,
            isNoResultsViewHidden: !noResults || !validQuery,
            isLoading: isLoading
        )
    }

    mutating func updateQuery(_ newQuery: String) -> [Effect] {
        query = newQuery
        isLoading = false

        guard TextSearchQuery.isValid(query: newQuery) else {
            results = []
            return [.cancelSearch]
        }

        return [.cancelSearch, .scheduleSearch]
    }

    mutating func clearResults() {
        results = []
        isLoading = false
    }

    mutating func showLoading() {
        isLoading = true
    }

    mutating func hideLoading() {
        isLoading = false
    }

    mutating func updateResults(_ messages: [ZMConversationMessage]) {
        results = messages
        isLoading = false
    }

    func routeForSelectingRow(at index: Int) -> Route {
        guard results.indices.contains(index) else {
            return .ignore
        }

        return .showInConversation(results[index])
    }

    func rowModel(at index: Int) -> TextSearchRowModel? {
        guard results.indices.contains(index) else {
            return nil
        }

        return TextSearchRowModel(message: results[index], queries: queryTerms)
    }

    private var queryTerms: [String] {
        query.components(separatedBy: .whitespacesAndNewlines)
    }
}
