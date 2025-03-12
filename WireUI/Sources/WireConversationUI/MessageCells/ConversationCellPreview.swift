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

@MainActor
func ConversationCellPreviews(
    models: [MessageCellModel]
) -> UIViewController {

    let tableViewController = UITableViewController(style: .plain)
    models.forEach { model in
        model.registerIfNeeded(in: tableViewController.tableView)
    }
    enum Section { case single }
    let dataSource = UITableViewDiffableDataSource<Section, [MessageCellModel].Index>(
        tableView: tableViewController.tableView!
    ) { tableView, indexPath, modelIndex in
        let model = models[modelIndex]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.cellReuseIdentifier, for: indexPath)
        model.configureCell(cell)
        return cell
    }
    tableViewController.dataSource = dataSource
    tableViewController.tableView!.separatorStyle = .none

    var snapshot = dataSource.snapshot()
    snapshot.appendSections([.single])
    snapshot.appendItems(Array(models.indices))
    dataSource.applySnapshotUsingReloadData(snapshot)

    return tableViewController
}

private extension UITableViewController {
    @MainActor
    var dataSource: (any UITableViewDataSource)? {
        get { objc_getAssociatedObject(self, &dataSourceKey) as? any UITableViewDataSource }
        set {
            objc_setAssociatedObject(self, &dataSourceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            tableView.dataSource = newValue
        }
    }
}

@MainActor private var dataSourceKey = 0
