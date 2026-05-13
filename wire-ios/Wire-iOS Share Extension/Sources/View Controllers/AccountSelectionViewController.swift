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
import WireDataModel

private let cellReuseIdentifier = "AccountCell"

final class AccountSelectionViewController: UITableViewController {

    private let viewModel: AccountSelectionViewModel

    var selectionHandler: ((_ account: Account) -> Void)?
    var cancellationHandler: (() -> Void)?

    init(accounts: [Account], current: Account?) {
        self.viewModel = AccountSelectionViewModel(
            accounts: accounts,
            currentAccount: current
        )

        super.init(style: .plain)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        definesPresentationContext = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.displayState.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.displayState.rows[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.subtitle
        cell.backgroundColor = .clear
        cell.accessoryType = row.isSelected ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let route = viewModel.routeForSelectingRow(at: indexPath.row) else {
            return
        }

        handle(route)
    }

    func cancelSelection() {
        handle(viewModel.routeForCancelTapped())
    }

    private func handle(_ route: AccountSelectionViewModel.Route) {
        switch route {
        case let .selectAccount(account):
            selectionHandler?(account)
        case .cancel:
            cancellationHandler?()
        }
    }
}
