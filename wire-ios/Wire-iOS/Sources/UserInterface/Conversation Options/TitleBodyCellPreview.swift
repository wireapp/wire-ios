//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class TitleBodyCellPreview: UITableViewController {

    enum SectionItemIdentifier {
        case single
    }

    private var dataSource: UITableViewDiffableDataSource<SectionItemIdentifier, SectionItemIdentifier>!

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
        tableView.register(TitleBodyCell.self, forCellReuseIdentifier: "TitleBodyCell")
    }

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, _ in
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleBodyCell", for: indexPath)
            if let cell = cell as? TitleBodyCell {
                cell.configure(
                    with: .titleAndBody(
                        title: "Your team doesn't use apps yet",
                        body: "To improve your workflow with apps, your team needs configuration. Please contact your team admin."
                    )
                )
            }
            return cell
        }
    }

    private func loadItems() {
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.single])
        snapshot.appendItems([.single])
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

}
