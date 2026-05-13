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
import WireDataModel

final class AccountSelectionViewModel {

    struct DisplayState {
        let rows: [Row]
        let emptyState: EmptyState?
        let errorState: ErrorState?
    }

    struct Row {
        let title: String
        let subtitle: String?
        let isSelected: Bool
    }

    struct EmptyState {}

    struct ErrorState {
        let message: String
    }

    enum Route {
        case selectAccount(Account)
        case cancel
    }

    private let accounts: [Account]

    let displayState: DisplayState

    init(
        accounts: [Account],
        currentAccount: Account?,
        errorMessage: String? = nil
    ) {
        self.accounts = accounts
        self.displayState = DisplayState(
            rows: accounts.map { account in
                Row(
                    title: account.userName,
                    subtitle: account.teamName,
                    isSelected: account == currentAccount
                )
            },
            emptyState: accounts.isEmpty ? EmptyState() : nil,
            errorState: errorMessage.map(ErrorState.init(message:))
        )
    }

    func routeForSelectingRow(at index: Int) -> Route? {
        guard accounts.indices.contains(index) else { return nil }

        return .selectAccount(accounts[index])
    }

    func routeForCancelTapped() -> Route {
        .cancel
    }
}
