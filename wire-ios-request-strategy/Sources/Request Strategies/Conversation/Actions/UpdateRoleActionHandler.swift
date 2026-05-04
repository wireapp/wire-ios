//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

class UpdateRoleActionHandler: ActionHandler<UpdateRoleAction> {

    private let localDomain: String?

    init(
        context: NSManagedObjectContext,
        localDomain: String?
    ) {
        self.localDomain = localDomain
        super.init(context: context)
    }

    override func request(for action: UpdateRoleAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let role = Role.existingObject(for: action.roleID, in: context),
            let participant = ZMUser.existingObject(for: action.userID, in: context),
            let roleName = role.name,
            let userID = participant.remoteIdentifier?.transportString(),
            let convID = conversation.remoteIdentifier?.transportString(),
            let payload = Payload.ConversationUpdateRole(role: roleName),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadString = String(bytes: payloadData, encoding: .utf8)
        else {
            var action = action
            action.notifyResult(.failure(UpdateRoleError.unknown))
            return nil
        }

        let path: String

        switch apiVersion {
        case .v0, .v1, .v2, .v3, .v4, .v5, .v6:
            path = "/conversations/\(convID)/members/\(userID)"
        case .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14, .v15:
            guard
                let convDomain = conversation.domain ?? localDomain,
                let userDomain = participant.domain ?? localDomain
            else {
                var action = action
                action.notifyResult(.failure(UpdateRoleError.missingDomains))
                return nil
            }

            path = "/conversations/\(convDomain)/\(convID)/members/\(userDomain)/\(userID)"
        }

        return ZMTransportRequest(
            path: path,
            method: .put,
            payload: payloadString as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: UpdateRoleAction) {
        var action = action

        switch response.httpStatus {
        case 200 ..< 300:
            guard
                let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
                let role = Role.existingObject(for: action.roleID, in: context),
                let participant = ZMUser.existingObject(for: action.userID, in: context)
            else {
                action.notifyResult(.failure(UpdateRoleError.unknown))
                return
            }

            conversation.addParticipantAndUpdateConversationState(user: participant, role: role)
            conversation.managedObjectContext?.saveOrRollback()
            action.notifyResult(.success(()))
        default:
            action.notifyResult(.failure(UpdateRoleError.unknown))
        }
    }
}
