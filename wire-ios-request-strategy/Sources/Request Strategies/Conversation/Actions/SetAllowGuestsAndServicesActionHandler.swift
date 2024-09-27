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

import WireDataModel

final class SetAllowGuestsAndServicesActionHandler: ActionHandler<SetAllowGuestsAndServicesAction> {
    // MARK: Internal

    // MARK: - Request Generation

    override func request(
        for action: SetAllowGuestsAndServicesAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let identifier = conversation.remoteIdentifier?.transportString() else {
            action.fail(with: .failedToRetrieveConversation)
            return nil
        }
        var accessRoles = conversation.accessRoles

        if action.allowServices {
            accessRoles.insert(.service)
        } else {
            accessRoles.remove(.service)
        }

        if action.allowGuests {
            accessRoles.insert(.guest)
            accessRoles.insert(.nonTeamMember)
        } else {
            accessRoles.remove(.guest)
            accessRoles.remove(.nonTeamMember)
        }

        var payload: [String: Any] = [
            "access": ConversationAccessMode.value(forAllowGuests: action.allowGuests).stringValue,
            "access_role": accessRoles.map(\.rawValue),
        ]

        let path: String
        switch apiVersion {
        case .v3, .v4, .v5, .v6:
            let domain =
                if let domain = conversation.domain, !domain.isEmpty {
                    domain
                } else {
                    BackendInfo.domain
                }
            guard let domain else {
                action.fail(with: .domainUnavailable)
                return nil
            }

            path = "/conversations/\(domain)/\(identifier)/access"

        case .v0, .v1, .v2:
            path = "/conversations/\(identifier)/access"
            payload["access_role_v2"] = accessRoles.map(\.rawValue)
        }

        return ZMTransportRequest(
            path: path,
            method: .put,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Request Handling

    override func handleResponse(_ response: ZMTransportResponse, action: SetAllowGuestsAndServicesAction) {
        var action = action

        guard let payload = response.payload,
              let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) else {
            action.fail(with: .failToDecodeResponsePayload)
            return
        }

        let success = {
            action.succeed()
        }

        Task {
            await eventProcessor.processAndSaveConversationEvents([updateEvent])
            success()
        }
    }

    // MARK: Private

    private lazy var eventProcessor = ConversationEventProcessor(context: context)
}
