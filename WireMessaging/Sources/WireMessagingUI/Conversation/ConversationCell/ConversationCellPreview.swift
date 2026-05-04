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

final class ConversationCellsPreview: UITableViewController {

    enum SectionIdentifier {
        case single
    }

    typealias ItemIdentifier = ConversationCellModel

    private let itemIdentifiers: [ItemIdentifier]
    private var dataSource: UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>!

    init(itemIdentifiers: [ItemIdentifier]) {
        self.itemIdentifiers = itemIdentifiers
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadItems()
    }

    private func setupTableView() {
        registerCellTypes()
        setupDataSource()
        tableView.separatorStyle = .none
    }

    private func registerCellTypes() {
        for itemIdentifier in itemIdentifiers {
            itemIdentifier.registerIfNeeded(in: tableView)
        }
    }

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: itemIdentifier.cellReuseIdentifier, for: indexPath)
            switch itemIdentifier {
            case let .timeDivider(timeDivider):
                guard let cell = cell as? ConversationCell<TimeDividerModel> else { break }
                cell.model = timeDivider
            default:
                assertionFailure("unexpected cell: \(cell)")
            }
            return cell
        }
    }

    private func loadItems() {
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.single])
        snapshot.appendItems(itemIdentifiers)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

}
