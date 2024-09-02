////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct SyncMLSOneToOneConversationAction: EntityAction {

    public typealias Result = (MLSGroupID, BackendMLSPublicKeys?)
    public typealias Failure = SyncMLSOneToOneConversationActionError

    public let userID: UUID
    public let domain: String
    public var resultHandler: ResultHandler?

    public init(
        userID: UUID,
        domain: String,
        resultHandler: ResultHandler? = nil
    ) {
        self.userID = userID
        self.domain = domain
        self.resultHandler = resultHandler
    }

}

public enum SyncMLSOneToOneConversationActionError: Error, Equatable {

    case endpointUnavailable
    case invalidDomain
    case invalidResponse
    case failedToProcessResponse
    case mlsNotEnabled
    case usersNotConnected
    case unknown(status: Int, label: String, message: String)

}
