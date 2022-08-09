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

/// An ID representing a identifying a single user client.

public struct MLSClientID: Equatable {

    // MARK: - Properties

    private let userID: String
    private let clientID: String
    private let domain: String

    // The string representation of the id.

    let string: String

    // MARK: - Life cycle

    init?(userClient: UserClient) {
        guard
            let userID = userClient.user?.remoteIdentifier.uuidString,
            let clientID = userClient.remoteIdentifier,
            let domain = userClient.user?.domain ?? APIVersion.domain
        else {
            return nil
        }

        self.init(
            userID: userID,
            clientID: clientID,
            domain: domain
        )
    }

    init(
        userID: String,
        clientID: String,
        domain: String
    ) {
        self.userID = userID.lowercased()
        self.clientID = clientID.lowercased()
        self.domain = domain.lowercased()
        self.string = "\(self.userID):\(self.clientID)@\(self.domain)"
    }

}
