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

import Foundation

public protocol UnauthenticatedSessionDelegate: AnyObject {

    /// Update credentials for the corresponding user session. Returns true if the credentials were accepted.
    func session(
        session: UnauthenticatedSession,
        updatedCredentials credentials: UserCredentials
    ) -> Bool

    func session(
        session: UnauthenticatedSession,
        updatedProfileImage imageData: Data
    )

    func session(
        session: UnauthenticatedSession,
        createdAccount account: Account
    )

    func session(
        session: UnauthenticatedSession,
        isExistingAccount account: Account
    ) -> Bool

    func sessionIsAllowedToCreateNewAccount(
        _ session: UnauthenticatedSession
    ) -> Bool

}
