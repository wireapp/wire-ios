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
import WireTransport

// MARK: - MLSClientID

/// An ID representing a identifying a single user client.
public struct MLSClientID: Equatable, Hashable {
    // MARK: - Properties

    public var userID: String
    public var clientID: String
    public var domain: String

    public var rawValue: String {
        "\(userID):\(clientID)@\(domain)"
    }

    public var data: Data? {
        rawValue.data(using: .utf8)
    }

    // MARK: - Life cycle

    public init?(user: ZMUser) {
        guard let selfClient = user.selfClient() else { return nil }
        self.init(userClient: selfClient)
    }

    public init?(userClient: UserClientType) {
        guard
            let userID = userClient.user?.remoteIdentifier.transportString(),
            let clientID = userClient.remoteIdentifier,
            let domain = userClient.user?.domain ?? BackendInfo.domain
        else {
            return nil
        }

        self.init(
            userID: userID,
            clientID: clientID,
            domain: domain
        )
    }

    public init(qualifiedClientID: QualifiedClientID) {
        self.init(
            userID: qualifiedClientID.userID.transportString(),
            clientID: qualifiedClientID.clientID,
            domain: qualifiedClientID.domain
        )
    }

    public init?(data: Data) {
        let string = String(decoding: data, as: UTF8.self)
        self.init(rawValue: string)
    }

    public init?(rawValue: String) {
        guard
            let regex = try? NSRegularExpression(pattern: "(.+):(.+)@(.+)", options: []),
            let result = regex.firstMatch(
                in: rawValue,
                options: [],
                range: NSRange(location: 0, length: rawValue.utf16.count)
            ),
            let userIDRange = Range(result.range(at: 1), in: rawValue),
            let clientIDRange = Range(result.range(at: 2), in: rawValue),
            let domainRange = Range(result.range(at: 3), in: rawValue)
        else {
            return nil
        }

        self.init(
            userID: String(rawValue[userIDRange]),
            clientID: String(rawValue[clientIDRange]),
            domain: String(rawValue[domainRange])
        )
    }

    public init(
        userID: String,
        clientID: String,
        domain: String
    ) {
        self.userID = userID.lowercased()
        self.clientID = clientID.lowercased()
        self.domain = domain.lowercased()
    }
}

// MARK: CustomStringConvertible

extension MLSClientID: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
