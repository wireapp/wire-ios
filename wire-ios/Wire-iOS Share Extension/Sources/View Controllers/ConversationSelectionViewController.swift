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

import UIKit
import WireCommonComponents
import WireDesign
import WireShareEngine

private let cellReuseIdentifier = "ConversationCell"

final class ConversationSelectionViewController: UITableViewController {

    private let viewModel: ConversationSelectionViewModel

    var selectionHandler: ((_ conversation: Conversation) -> Void)?

    private let searchController = UISearchController(searchResultsController: nil)
    private var clipboardDelegate: ClipboardRestrictedTextFieldDelegate?

    init(conversations: [Conversation]) {
        self.viewModel = ConversationSelectionViewModel(conversations: conversations)

        super.init(style: .plain)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(TargetConversationCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.isTranslucent = false

        preferredContentSize = UIScreen.main.bounds.size
        definesPresentationContext = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        let searchBar = searchController.searchBar
        tableView.tableHeaderView = searchBar

        clipboardDelegate = ClipboardRestrictedTextFieldDelegate.restrictSearchBarIfNeeded(
            searchBar,
            isContextMenuAllowed: SecurityFlags.clipboard.isEnabled
        )
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.displayState.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = viewModel.visibleConversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellReuseIdentifier,
            for: indexPath
        ) as! TargetConversationCell
        cell.configure(for: conversation)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let route = viewModel.routeForSelectingRow(at: indexPath.row) else { return }

        switch route {
        case let .selectConversation(conversation):
            selectionHandler?(conversation)
        }
    }
}

extension ConversationSelectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchText(searchController.searchBar.text)
        tableView.reloadData()
    }
}
