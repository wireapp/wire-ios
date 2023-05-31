//
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

public class LeaveMLSSubconversationAction: EntityAction {
    public typealias Result = Void

    public enum Failure: Error, Equatable {
        case endpointUnavailable
        case emptyParameters
        case invalidParameters
        case noConversation
        case conversationIdOrDomainNotFound
        case accessDenied
        case mlsNotEnabled
        case mlsProtocolError
        case mlsStaleMessage
        case unknown(status: Int, label: String, message: String)

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                return "Endpoint unavailable"
            case .emptyParameters:
                return "Empty parameters"
            case .invalidParameters:
                return "Invalid conversation ID or domain"
            case .noConversation:
                return "Conversation not found"
            case .conversationIdOrDomainNotFound:
                return "Conversation ID or domain not found"
            case .accessDenied:
                return "Conversation access denied"
            case .mlsNotEnabled:
                return "MLS is not configured on this backend"
            case .mlsProtocolError:
                return "MLS protocol error"
            case .mlsStaleMessage:
                return "The conversation epoch in a message is too old"
            case let .unknown(status, label, message):
                return "Unknown error (response status: \(status), label: \(label), message: \(message))"
            }
        }
    }

    public let conversationID: UUID
    public let domain: String
    public let type: SubgroupType
    public var resultHandler: ResultHandler?

    public init(conversationID: UUID, domain: String, type: SubgroupType, resultHandler: ResultHandler? = nil) {
        self.resultHandler = resultHandler
        self.conversationID = conversationID
        self.type = type
        self.domain = domain
    }

}
