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
import WireDataModel

class CreateConversationGuestLinkActionHandler: ActionHandler<CreateConversationGuestLinkAction> {

    // MARK: - Request generation

    override func request(
        for action: ActionHandler<CreateConversationGuestLinkAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        guard let conversation = ZMConversation.existingObject(for: action.parameters.conversationID, in: context),
              let identifier = conversation.remoteIdentifier?.transportString() else {
            fatalError("Conversation is not yet inserted on the backend")
        }

        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            // For these versions, no payload is required.
            return ZMTransportRequest(path: "/conversations/\(identifier)/code", method: .post, payload: nil, apiVersion: apiVersion.rawValue)
        case .v4, .v5, .v6:
            // For these versions, a payload may include a password.
            var payload: [String: Any] = [:]
            if let password = action.parameters.password {
                payload["password"] = password
            }
            return ZMTransportRequest(path: "/conversations/\(identifier)/code", method: .post, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        }
    }

    // MARK: - Request handling 

    override func handleResponse(_ response: ZMTransportResponse, action: CreateConversationGuestLinkAction) {

        var action = action

        switch response.httpStatus {
        case 201:
            guard let payload = response.payload?.asDictionary(),
                  let data = payload["data"] as? [String: Any],
                  let uri = data["uri"] as? String else {
                let errorInfo = response.errorInfo
                action.fail(with: .unknownError(code: errorInfo.status, label: errorInfo.label, message: errorInfo.message))
                return
            }
            action.succeed(with: uri)

        default:
            let errorInfo = response.errorInfo
            action.fail(with: .unknownError(code: errorInfo.status, label: errorInfo.label, message: errorInfo.message))
        }
    }

}
