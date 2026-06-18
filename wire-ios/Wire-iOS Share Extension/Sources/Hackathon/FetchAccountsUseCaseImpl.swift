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
import WireDomain
import WireNetwork
import WireTransport
import WireShareExtensionCore

struct FetchAccountsUseCaseImpl: FetchAccountsUseCase {

    let accountManager: AccountManager
    let cookieStorage: CookieStorage

    func callAsFunction() async throws -> [Account] {
        accountManager.accounts.map { account in
            let legacyCookieStorage = LegacyCookieStorage(
                userIdentifier: account.userIdentifier,
                cookieStorage: cookieStorage
            )
            return WireShareExtensionCore.Account(
                id: account.userIdentifier,
                name: account.userName,
                isAuthenticated: legacyCookieStorage.hasAuthenticationCookie
            )
        }
    }

}
