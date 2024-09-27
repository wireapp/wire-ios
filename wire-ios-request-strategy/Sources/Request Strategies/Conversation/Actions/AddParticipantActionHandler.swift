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

extension ConversationAddParticipantsError {
    public init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (403, "access-denied"?): self = .accessDenied
        case (403, "not-connected"?): self = .notConnectedToUser
        case (404, "no-conversation"?): self = .conversationNotFound
        case (403, "too-many-members"?): self = .tooManyMembers
        case (412, "missing-legalhold-consent"?): self = .missingLegalHoldConsent
        case (400 ..< 499, _): self = .unknown
        default: return nil
        }
    }
}

// MARK: - AddParticipantActionHandler

class AddParticipantActionHandler: ActionHandler<AddParticipantAction> {
    let decoder: JSONDecoder = .defaultDecoder

    private let eventProcessor: ConversationEventProcessorProtocol

    override convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            eventProcessor: ConversationEventProcessor(context: context)
        )
    }

    init(
        context: NSManagedObjectContext,
        eventProcessor: ConversationEventProcessorProtocol
    ) {
        self.eventProcessor = eventProcessor
        super.init(context: context)
    }

    override func request(for action: AddParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            v0Request(for: action)
        case .v1:
            v1Request(for: action)
        case .v2, .v3, .v4, .v5, .v6:
            v2Request(for: action, apiVersion: apiVersion)
        }
    }

    private func v0Request(for action: AddParticipantAction) -> ZMTransportRequest? {
        var action = action

        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.remoteIdentifier?.transportString(),
            let users: [ZMUser] = action.userIDs.existingObjects(in: context),
            let payload = Payload.ConversationAddMember(userIDs: users.compactMap(\.remoteIdentifier)),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID)/members"
        return ZMTransportRequest(path: path, method: .post, payload: payloadAsString as ZMTransportData, apiVersion: 0)
    }

    private func v1Request(for action: AddParticipantAction) -> ZMTransportRequest? {
        var action = action

        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.qualifiedID,
            let payload = payload(for: action)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID.uuid)/members/v2"
        return ZMTransportRequest(path: path, method: .post, payload: payload, apiVersion: 1)
    }

    private func v2Request(for action: AddParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.qualifiedID,
            let payload = payload(for: action)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID.domain)/\(conversationID.uuid)/members"
        return ZMTransportRequest(path: path, method: .post, payload: payload, apiVersion: apiVersion.rawValue)
    }

    private func payload(for action: AddParticipantAction) -> ZMTransportData? {
        guard
            let users: [ZMUser] = action.userIDs.existingObjects(in: context),
            let qualifiedUserIDs = users.qualifiedUserIDs,
            let payload = Payload.ConversationAddMember(qualifiedUserIDs: qualifiedUserIDs),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        return payloadAsString as ZMTransportData
    }

    override func handleResponse(_ response: ZMTransportResponse, action: AddParticipantAction) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let payload = response.payload,
                let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            else {
                Logging.network.warn("Can't process response, aborting.")
                action.fail(with: .unknown)
                return
            }
            let success = {
                action.succeed()
            }
            Task {
                await eventProcessor.processAndSaveConversationEvents([updateEvent])
                success()
            }

        case 204:
            action.succeed()

        case 403:
            // Refresh user data since this operation might have failed
            // due to a team member being removed/deleted from the team.
            let users: [ZMUser]? = action.userIDs.existingObjects(in: context)
            users?.filter(\.isTeamMember).forEach { $0.refreshData() }

            action.fail(with: ConversationAddParticipantsError(response: response) ?? .unknown)

        case 409:
            guard
                let payload = ErrorResponse(response),
                let nonFederatingDomains = payload.non_federating_backends
            else {
                return action.fail(with: .unknown)
            }

            if nonFederatingDomains.isEmpty {
                action.succeed()
            } else {
                action.fail(with: .nonFederatingDomains(Set(nonFederatingDomains)))
            }

        case 533:
            guard
                let payload = ErrorResponse(response),
                let unreachableDomains = payload.unreachable_backends
            else {
                return action.fail(with: .unknown)
            }

            if unreachableDomains.isEmpty {
                action.succeed()
            } else {
                action.fail(with: .unreachableDomains(Set(unreachableDomains)))
            }

        default:
            action.fail(with: ConversationAddParticipantsError(response: response) ?? .unknown)
        }
    }
}

// MARK: AddParticipantActionHandler.ErrorResponse

extension AddParticipantActionHandler {
    // MARK: - Error response

    struct ErrorResponse: Codable {
        var unreachable_backends: [String]?
        var non_federating_backends: [String]?
    }
}
