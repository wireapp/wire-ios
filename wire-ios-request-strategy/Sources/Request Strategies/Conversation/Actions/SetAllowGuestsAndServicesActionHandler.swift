//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class SetAllowGuestsAndAppsActionHandler: ActionHandler<SetAllowGuestsAndAppsAction> {

    private let eventProcessor: ConversationEventProcessor
    private let localDomain: String?

    init(
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.eventProcessor = ConversationEventProcessor(
            context: context,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.localDomain = localDomain
        super.init(context: context)
    }

    // MARK: - Request Generation

    override func request(
        for action: SetAllowGuestsAndAppsAction,
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

        if action.allowApps {
            accessRoles.insert(.app)
        } else {
            accessRoles.remove(.app)
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
            "access_role": accessRoles.map(\.rawValue)
        ]

        let path: String
        switch apiVersion {
        case .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14:
            let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { localDomain }
            guard let domain else {
                action.fail(with: .domainUnavailable)
                return nil
            }

            path = "/conversations/\(domain)/\(identifier)/access"
        case .v2, .v1, .v0:
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

    override func handleResponse(_ response: ZMTransportResponse, action: SetAllowGuestsAndAppsAction) {

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

}
