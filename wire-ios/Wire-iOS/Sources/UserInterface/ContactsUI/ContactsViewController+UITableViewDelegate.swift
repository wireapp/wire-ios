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

extension ContactsViewController: UITableViewDelegate {
    func headerTitle(section: Int) -> String? {
        dataSource.tableView(tableView, titleForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = headerTitle(section: section), !title.isEmpty else {
            return nil
        }
        let headerView = tableView.dequeueReusableHeaderFooter(ofType: ContactsSectionHeaderView.self)
        headerView.label.text = title
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = headerTitle(section: section), !title.isEmpty else {
            return 0
        }
        return ContactsSectionHeaderView.height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        CGFloat.StartUI.CellHeight
    }
}
