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
import Foundation
import NeedleFoundation
internal import WireAuthenticationUI
import WireFoundation
import WireMultiBackendUI
import WireNetwork

protocol AccountSwitcherComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var accountsPublisher: CurrentValuePublisher<[AccountUIModel]> { get }
    var environment: BackendEnvironment2 { get }

}

final class AccountSwitcherComponent: Component<AccountSwitcherComponentDependency> {}

extension AccountSwitcherComponent: AccountSwitcherFactory {

    // MARK: - Factory

    @MainActor var viewModel: AccountSwitcherModalViewModel {
        AccountSwitcherModalViewModel(
            accountsPublisher: dependency.accountsPublisher,
            router: dependency.router,
            defaultEnvironment: dependency.environment
        )
    }
}
