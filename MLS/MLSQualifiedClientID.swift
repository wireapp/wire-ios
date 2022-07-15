//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// MLS qualified client identifier for initialising Corecrypto
public struct MLSQualifiedClientID {

    // MARK: - Properties

    private let user: ZMUser

    public var qualifiedClientId: String? {
        guard
            let clientId = user.selfClient()?.remoteIdentifier,
            let userId = user.remoteIdentifier,
            let domain = user.domain?.selfOrNilIfEmpty ?? APIVersion.domain
        else {
            return nil
        }

        return "\(userId):\(clientId)@\(domain)"
    }

    // MARK: - Methods

    public init(user: ZMUser) {
        self.user = user
    }
}
