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

public struct E2EIClientID: Equatable, Hashable {
    // MARK: Lifecycle

    public init(
        userID: String,
        clientID: String,
        domain: String
    ) {
        self.userID = userID.lowercased()
        self.clientID = clientID.lowercased()
        self.domain = domain.lowercased()
    }

    public init?(user: ZMUser) {
        guard let selfClient = user.selfClient(),
              let userID = selfClient.user?.remoteIdentifier.transportString(),
              let clientID = selfClient.remoteIdentifier,
              let domain = selfClient.user?.domain ?? BackendInfo.domain
        else {
            return nil
        }
        self.init(
            userID: userID,
            clientID: clientID,
            domain: domain
        )
    }

    // MARK: Public

    // MARK: - Properties

    public let userID: String
    public let clientID: String
    public let domain: String

    // The string representation of the id.

    public var rawValue: String {
        "\(userID):\(clientID)@\(domain)"
    }
}
