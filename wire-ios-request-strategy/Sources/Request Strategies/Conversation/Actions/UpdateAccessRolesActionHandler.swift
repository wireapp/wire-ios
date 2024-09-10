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

extension UpdateAccessRolesError {

    public init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (403, "access-denied"?): self = .accessDenied
        case (403, "action-denied"?): self = .actionDenied
        case (404, "no-conversation"?): self = .conversationNotFound
        case (400..<499, _): self = .unknown
        default: return nil
        }
    }

}

final class UpdateAccessRolesActionHandler: ActionHandler<UpdateAccessRolesAction> {

    private lazy var eventProcessor = ConversationEventProcessor(context: context)

    // MARK: - Methods

    override func request(for action: UpdateAccessRolesAction, apiVersion: APIVersion) -> ZMTransportRequest? {

        let payload = Payload.UpdateConversationAccess(accessMode: action.accessMode, accessRoles: action.accessRoles)

        guard let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
              let conversationID = conversation.remoteIdentifier?.transportString(),
              let payloadData = payload.payloadData(encoder: .defaultEncoder),
              let payloadAsString = String(bytes: payloadData, encoding: .utf8) else {
                  return nil
              }

        switch apiVersion {

        case .v0:
            return ZMTransportRequest(path: "/conversations/\(conversationID)/access",
                                      method: .put,
                                      payload: payloadAsString as ZMTransportData?,
                                      apiVersion: apiVersion.rawValue)

        case .v1, .v2, .v3, .v4, .v5, .v6:
            let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { BackendInfo.domain }
            guard let domain else { return nil }

            return ZMTransportRequest(
                path: "/conversations/\(domain)/\(conversationID)/access",
                method: .put,
                payload: payloadAsString as ZMTransportData?,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    override func handleResponse(_ response: ZMTransportResponse, action: UpdateAccessRolesAction) {

        var action = action

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

            let success = {
                action.notifyResult(.success(Void()))
            }
            Task {
                await eventProcessor.processAndSaveConversationEvents([updateEvent])
                success()
            }

        default:
            action.notifyResult(.failure(UpdateAccessRolesError(response: response) ?? .unknown))
        }

    }

}
