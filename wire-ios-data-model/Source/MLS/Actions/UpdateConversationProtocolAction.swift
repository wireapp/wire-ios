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

    // MARK: - Types

    public typealias Result = Void // [ZMUpdateEvent]

    public enum Failure: String, LocalizedError, Equatable {

        // 400
        case mlsMigrationCriteriaNotSatisfied = "mls-migration-criteria-not-satisfied"

        // 403
        case operationDenied = "operation-denied"
        case noTeamMember = "no-team-member"
        case invalidOp = "invalid-op"
        case actionDenied = "action-denied"
        case invalidProtocolTransition = "invalid-protocol-transition"

        // 404
        case cnvDomainOrCNVNotFound // TODO: how does response look like?
        case noTeam = "no-team"
        case noConversation = "no-conversation"

        public var errorDescription: String? {
            switch self {

                // 400

            case .mlsMigrationCriteriaNotSatisfied:
                return "The migration criteria for mixed to MLS protocol transition are not satisfied for this conversation"

                // 403

            case .operationDenied:
                return "Insufficient permissions"
            case .noTeamMember:
                return "Requesting user is not a team member"
            case .invalidOp:
                return "Invalid operation"
            case .actionDenied:
                return "Insufficient authorization (missing leave_conversation)"
            case .invalidProtocolTransition:
                return "Protocol transition is invalid"

                // 404

            case .cnvDomainOrCNVNotFound:
                return "cnv_domain or cnv not found"
            case .noTeam:
                return "Team not found"
            case .noConversation:
                return "Conversation not found"
            }
        }
    }

    // MARK: - Properties

    public var domain: String
    public var conversationID: UUID
    public var resultHandler: ResultHandler?

    // MARK: - Life cycle

    public init(
        domain: String,
        conversationID: UUID,
        resultHandler: ResultHandler?
    ) {
        self.domain = domain
        self.conversationID = conversationID
        self.resultHandler = resultHandler
    }
}
