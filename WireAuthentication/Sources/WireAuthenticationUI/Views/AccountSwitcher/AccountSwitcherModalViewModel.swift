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

import Combine
import SwiftUI
import WireFoundation
import WireMultiBackendUI
import WireNetwork

@MainActor
package class AccountSwitcherModalViewModel: ObservableObject {

    @Published var accounts: [AccountUIModel]

    private let router: any Router
    private var cancellables = Set<AnyCancellable>()
    private let defaultEnvironment: BackendEnvironment2

    package init(
        accountsPublisher: CurrentValuePublisher<[AccountUIModel]>,
        router: any Router,
        defaultEnvironment: BackendEnvironment2
    ) {
        self.accounts = accountsPublisher.value
        self.router = router
        self.defaultEnvironment = defaultEnvironment
        accountsPublisher.sink { [weak self] accounts in
            self?.accounts = accounts
        }.store(in: &cancellables)
    }

    func onCloseButtonTapped() {
        router.presentSheet(.authFlow(environment: defaultEnvironment))
    }
}
