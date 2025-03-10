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

import NeedleFoundation
import WireDataModel

/// Root of the dependencies tree graph.
final class RootComponent: BootstrapComponent {

    public let accountManager: AccountManager
    public let userID: UUID
    public let applicationIdentifier: String
    public let applicationContainer: URL
    public let selectedAccount: Account
    public let contentHandler: (UNNotificationContent) -> Void

    init(
        accountManager: AccountManager,
        userID: UUID,
        applicationIdentifier: String,
        applicationContainer: URL,
        selectedAccount: Account,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.accountManager = accountManager
        self.userID = userID
        self.applicationIdentifier = applicationIdentifier
        self.applicationContainer = applicationContainer
        self.selectedAccount = selectedAccount
        self.contentHandler = contentHandler

        super.init()
    }

    var verifyUserSession: VerifyUserSession {
        verifyComponent.verifyUserSession
    }

    // MARK: - Children

    var verifyComponent: VerifyUserComponent {
        VerifyUserComponent(parent: self)
    }

}
