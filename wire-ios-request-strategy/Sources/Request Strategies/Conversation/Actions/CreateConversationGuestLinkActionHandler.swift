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
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        let identifier = action.conversationID.transportString()

        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            return ZMTransportRequest(
                path: "/conversations/\(identifier)/code",
                method: .post,
                payload: nil,
                apiVersion: apiVersion.rawValue
            )
        case .v4, .v5, .v6:
            // For these versions, a payload may include a password.
            var payload: [String: Any] = [:]
            if let password = action.password {
                payload["password"] = password
            }
            return ZMTransportRequest(
                path: "/conversations/\(identifier)/code",
                method: .post,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )
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

                let errorInfo = CreateConversationGuestLinkError(response: response)
                action.fail(with: errorInfo ?? .unknown)
                return
            }

            action.succeed(with: uri)

        case 200:
            guard let payload = response.payload?.asDictionary(),
                  let uri = payload["uri"] as? String else {

                let errorInfo = CreateConversationGuestLinkError(response: response)
                action.fail(with: errorInfo ?? .unknown)
                return
            }

            action.succeed(with: uri)

        default:
            let errorInfo = CreateConversationGuestLinkError(response: response)
            action.fail(with: errorInfo ?? .unknown)
        }
    }

}
