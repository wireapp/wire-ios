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

import WireDataModel
import WireSyncEngine

struct ZClientControllerBuilder {

    private(set) var account: Account
    private(set) var userSession: UserSession

    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(account: account, userSession: userSession)
        viewController.router = router
        return viewController
    }

    func callAsFunction(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        build(router: router)
    }
}
