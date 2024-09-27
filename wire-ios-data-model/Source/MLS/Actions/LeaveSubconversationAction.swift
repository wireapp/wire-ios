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

public final class LeaveSubconversationAction: EntityAction {
    // MARK: Lifecycle

    public init(
        conversationID: UUID,
        domain: String,
        subconversationType: SubgroupType,
        resultHandler: ResultHandler? = nil
    ) {
        self.conversationID = conversationID
        self.domain = domain
        self.subconversationType = subconversationType
        self.resultHandler = resultHandler
    }

    // MARK: Public

    public typealias Result = Void

    public enum Failure: Error, Equatable {
        case endpointUnavailable
        case invalidParameters
        case mlsNotEnabled
        case mlsProtocolError
        case accessDenied
        case noConversation
        case mlsStaleMessage
        case unknown(status: Int, label: String, message: String)
    }

    // MARK: - Properties

    public let conversationID: UUID
    public let domain: String
    public let subconversationType: SubgroupType
    public var resultHandler: ResultHandler?
}
