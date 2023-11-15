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

import WireDataModel

final class UpdateConversationProtocolActionHandler: ActionHandler<UpdateConversationProtocolAction> {

    typealias EventPayload = [AnyHashable: Any]

    // MARK: - Methods

    override func request(
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return .none
        }

        let path = "/conversations/\(action.domain)/\(action.conversationID.transportString())/\(action.messageProtocol.stringValue)"
        let payload = ["protocol": action.messageProtocol.stringValue] as ZMTransportData

        return .init(
            path: path,
            method: .put,
            payload: payload,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: Action
    ) {
        var action = action

        switch response.httpStatus {

        case 200, 204:
            action.succeed()

        default:
            let label = response.payloadLabel()
            let message = response.payload?.asDictionary()?["message"] as? String
            let error = Action.Failure.api(statusCode: response.httpStatus, label: label ?? "", message: message ?? "")
            action.fail(with: error)
        }
    }
}
