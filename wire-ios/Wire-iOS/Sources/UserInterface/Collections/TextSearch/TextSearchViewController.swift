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

final class TextSearchViewController: NSObject {
    let resultsView: TextSearchResultsView = .init()
    let searchBar: TextSearchInputView = .init()

    weak var delegate: MessageActionResponder? = .none
    let conversation: ConversationLike
    var searchQuery: String? {
        viewModel.query
    }

    private var viewModel = TextSearchViewModel()
    private var textSearchQuery: TextSearchQuery?

    private let userSession: UserSession

    init(conversation: ConversationLike, userSession: UserSession) {
        self.conversation = conversation
        self.userSession = userSession
        super.init()
        loadViews()
    }

    private func loadViews() {
        applyViewState()

        resultsView.tableView.delegate = self
        resultsView.tableView.dataSource = self

        searchBar.delegate = self
        searchBar.placeholderString = viewModel.searchPlaceholder
        resultsView.noResultsView.label.accessibilityLabel = viewModel.noResultsAccessibilityLabel
        resultsView.noResultsView.label.text = viewModel.noResultsText
    }

    func teardown() {
        textSearchQuery?.cancel()
    }

    private func scheduleSearch() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        perform(searchSelector, with: .none, afterDelay: 0.2)
    }

    @objc
    private func search() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        textSearchQuery?.cancel()
        textSearchQuery = nil

        guard let query = searchQuery, !query.isEmpty else {
            viewModel.clearResults()
            applyViewStateAndReloadResults()
            return
        }

        textSearchQuery = TextSearchQuery(conversation: conversation, query: query, delegate: self)
        if let query = textSearchQuery {
            perform(#selector(showLoadingSpinner), with: nil, afterDelay: 2)
            query.execute()
        }
    }

    private func applyViewStateAndReloadResults() {
        applyViewState()
        resultsView.tableView.reloadData()
        setupAccessibility()
    }

    private func applyViewState() {
        let viewState = viewModel.viewState
        resultsView.isHidden = viewState.isResultsViewHidden
        resultsView.tableView.isHidden = viewState.isTableViewHidden
        resultsView.noResultsView.isHidden = viewState.isNoResultsViewHidden
        searchBar.isLoading = viewState.isLoading
    }

    @objc
    private func showLoadingSpinner() {
        viewModel.showLoading()
        applyViewState()
    }

    private func hideLoadingSpinner() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoadingSpinner), object: nil)
        viewModel.hideLoading()
        applyViewState()
    }

    private func applyEffects(_ effects: [TextSearchViewModel.Effect]) {
        for effect in effects {
            switch effect {
            case .cancelSearch:
                textSearchQuery?.cancel()
            case .scheduleSearch:
                scheduleSearch()
            }
        }
    }

    private func setupAccessibility() {
        /// If noResultsView is not hidden, we should hide elements in the collectionView that are not currently
        /// visible.
        if let superview = resultsView.superview as? CollectionsView {
            superview.collectionView.accessibilityElementsHidden = !resultsView.noResultsView.isHidden
        }
    }

}

extension TextSearchViewController: TextSearchQueryDelegate {
    func textSearchQueryDidReceive(result: TextQueryResult) {
        guard result.query == textSearchQuery else { return }
        if !result.matches.isEmpty || !result.hasMore {
            hideLoadingSpinner()
            viewModel.updateResults(result.matches)
            applyViewStateAndReloadResults()
        }
    }
}

extension TextSearchViewController: TextSearchInputViewDelegate {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo query: String) {
        hideLoadingSpinner()
        applyEffects(viewModel.updateQuery(query))
        applyViewStateAndReloadResults()
    }

    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool {
        TextSearchQuery.isValid(query: viewModel.query)
    }
}

extension TextSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: TextSearchResultCell.reuseIdentifier) as! TextSearchResultCell
        guard let rowModel = viewModel.rowModel(at: indexPath.row) else {
            return cell
        }

        cell.configure(
            with: rowModel.message,
            queries: rowModel.queries,
            userSession: userSession
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.routeForSelectingRow(at: indexPath.row) {
        case let .showInConversation(message):
            delegate?.perform(action: .showInConversation, for: message, view: tableView)
        case .ignore:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.searchInput.endEditing(true)
    }
}
