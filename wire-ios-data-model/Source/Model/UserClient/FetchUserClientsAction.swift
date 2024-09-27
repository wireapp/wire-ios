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

// MARK: - QualifiedClientID

public struct QualifiedClientID: Hashable {
    public let userID: UUID
    public let domain: String
    public let clientID: String

    public init(userID: UUID, domain: String, clientID: String) {
        self.userID = userID
        self.domain = domain
        self.clientID = clientID
    }
}

// MARK: - FetchUserClientsAction

/// An action to fetch all user client IDs given a set of
/// user IDs.

public final class FetchUserClientsAction: EntityAction {
    // MARK: - Types

    public typealias Result = Set<QualifiedClientID>

    public enum Failure: Error, Equatable {
        case endpointUnavailable
        case malformdRequestPayload
        case failedToEncodeRequestPayload
        case missingResponsePayload
        case failedToDecodeResponsePayload
        case unknown(status: Int, label: String, message: String)
    }

    // MARK: - Properties

    public let userIDs: Set<QualifiedID>
    public var resultHandler: ResultHandler?

    // MARK: - Life cycle

    public init(
        userIDs: Set<QualifiedID>,
        resultHandler: ResultHandler? = nil
    ) {
        self.userIDs = userIDs
        self.resultHandler = resultHandler
    }
}
