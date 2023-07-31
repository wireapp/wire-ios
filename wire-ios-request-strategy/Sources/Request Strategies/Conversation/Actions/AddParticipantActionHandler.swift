// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
       case (400..<499, _): self = .unknown
       case (523, "federation-unreachable-domains-error"):self = .unreachableDomains
       default: return nil
       }
   }

}

class AddParticipantActionHandler: ActionHandler<AddParticipantAction> {

    let decoder: JSONDecoder = .defaultDecoder

    private let eventProcessor: ConversationEventProcessorProtocol

    convenience required init(context: NSManagedObjectContext) {
        self.init(context: context, eventProcessor: ConversationEventProcessor(context: context))
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
            return v0Request(for: action)
        case .v1:
            return v1Request(for: action)
        case .v2, .v3:
            return v2Request(for: action)
        case .v4:
            return v4Request(for: action)
        }
    }

    private func v0Request(for action: AddParticipantAction) -> ZMTransportRequest? {
        var action = action

        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.remoteIdentifier?.transportString(),
            let users: [ZMUser] = action.userIDs.existingObjects(in: context),
            let payload =  Payload.ConversationAddMember(userIDs: users.compactMap(\.remoteIdentifier)),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID)/members"
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData, apiVersion: 0)
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
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payload, apiVersion: 1)
    }

    private func v2Request(for action: AddParticipantAction) -> ZMTransportRequest? {
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
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payload, apiVersion: 2)
    }

    private func v4Request(for action: AddParticipantAction) -> ZMTransportRequest? {
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
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payload, apiVersion: 4)
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

        guard response.result == .success else {

            guard let failure = Payload.ResponseFailure(response, decoder: decoder) else {
                action.notifyResult(.failure(.unknown))
                return
            }

            switch (failure.code, failure.label) {
            case (403, _):
                // Refresh user data since this operation might have failed
                // due to a team member being removed/deleted from the team.
                let users: [ZMUser]? = action.userIDs.existingObjects(in: context)
                users?.filter(\.isTeamMember).forEach({ $0.refreshData() })

                action.notifyResult(.failure(ConversationAddParticipantsError(response: response) ?? .unknown))
            case (523, .unreachableDomains):
                action.notifyResult(.failure(.unreachableDomains))
            default:
                action.notifyResult(.failure(ConversationAddParticipantsError(response: response) ?? .unknown))
            }

            return
        }

        switch response.httpStatus {
        case 200:

            guard
                let payload = response.payload,
                let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            else {
                Logging.network.warn("Can't process response, aborting.")
                action.notifyResult(.failure(.unknown))
                return
            }

            eventProcessor.processConversationEvents([updateEvent])

            action.notifyResult(.success(Void()))

        case 204:
            action.notifyResult(.success(Void()))
        default:
            action.notifyResult(.failure(.unknown))
        }
    }

}
