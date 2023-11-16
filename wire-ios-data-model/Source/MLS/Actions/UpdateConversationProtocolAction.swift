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

public struct UpdateConversationProtocolAction: EntityAction {

    // MARK: - Properties

    public var qualifiedID: QualifiedID
    public var messageProtocol: MessageProtocol
    public var resultHandler: ResultHandler?

    // MARK: - Life cycle

    public init(
        qualifiedID: QualifiedID,
        messageProtocol: MessageProtocol
    ) {
        self.qualifiedID = qualifiedID
        self.messageProtocol = messageProtocol
    }

}

extension UpdateConversationProtocolAction {

    // MARK: - Types

    public typealias Result = Void

    public enum Failure: Equatable, Error {

        case endpointUnavailable
        case api(APIFailure)
        case unknown

        public enum APIFailure: String, CaseIterable, Equatable {

            // 400
            case mlsMigrationCriteriaNotSatisfied = "mls-migration-criteria-not-satisfied"

            // 403
            case operationDenied = "operation-denied"
            case noTeamMember = "no-team-member"
            case invalidOp = "invalid-op"
            case actionDenied = "action-denied"
            case invalidProtocolTransition = "invalid-protocol-transition"

            // 404
            case conversationIdOrDomainNotFound = "Conversation ID or domain not found."
            case noTeam = "no-team"
            case noConversation = "no-conversation"

            public var statusCode: Int {
                switch self {
                case .mlsMigrationCriteriaNotSatisfied:
                    return 400
                case .operationDenied, .noTeamMember, .invalidOp, .actionDenied, .invalidProtocolTransition:
                    return 403
                case .conversationIdOrDomainNotFound, .noTeam, .noConversation:
                    return 404
                }
            }
        }
    }
}
