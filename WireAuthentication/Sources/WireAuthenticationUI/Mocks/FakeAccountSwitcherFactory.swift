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
import WireFoundation
import WireMultiBackendUI
import WireNetwork

struct FakeAccountSwitcherFactory: AccountSwitcherFactory {

    let accounts: [AccountUIModel]
    let defaultEnvironment: BackendEnvironment2

    init(
        accounts: [AccountUIModel],
        defaultEnvironment: BackendEnvironment2
    ) {
        self.accounts = accounts
        self.defaultEnvironment = defaultEnvironment
    }

    var viewModel: AccountSwitcherModalViewModel {
        .init(
            accountsPublisher: CurrentValuePublisher(subject: CurrentValueSubject(accounts)),
            router: FakeRootFactory().viewModel,
            defaultEnvironment: defaultEnvironment
        )
    }
}
