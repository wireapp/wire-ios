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

/// A qualified id for MLS clients.

public struct MLSQualifiedClientID {

    // MARK: - Properties

    public let rawValue: String

    // MARK: - Life cycle

    init?(user: ZMUser) {
        guard
            let userID = user.remoteIdentifier,
            let clientID = user.selfClient()?.remoteIdentifier,
            let domain = user.domain?.selfOrNilIfEmpty ?? BackendInfo.domain
        else {
            return nil
        }

        self.init(
            userID: userID.transportString(),
            clientID: clientID,
            domain: domain
        )
    }

    init?(rawValue: String) {
        var components = rawValue.split(separator: ":")

        guard
            components.count == 2,
            let userID = components.element(atIndex: 0),
            let rest = components.element(atIndex: 1)
        else {
            return nil
        }

        components = rest.split(separator: "@")

        guard
            components.count == 2,
            let clientID = components.element(atIndex: 0),
            let domain = components.element(atIndex: 1)
        else {
            return nil
        }

        self.init(
            userID: String(userID),
            clientID: String(clientID),
            domain: String(domain)
        )
    }

    init?(
        userID: String,
        clientID: String,
        domain: String
    ) {
        guard
            userID.isNonEmpty,
            clientID.isNonEmpty,
            domain.isNonEmpty
        else {
            return nil
        }

        rawValue = "\(userID):\(clientID)@\(domain)".lowercased()
    }

}
