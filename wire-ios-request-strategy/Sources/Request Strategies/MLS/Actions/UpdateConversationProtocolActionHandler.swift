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

        let domain = action.qualifiedID.domain
        let conversationID = action.qualifiedID.uuid.transportString()
        let messageProtocol = action.messageProtocol.stringValue
        let path = "/conversations/\(domain)/\(conversationID)/\(messageProtocol)"
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

        if [200, 204].contains(response.httpStatus) {
            return action.succeed()
        }

        if
            let label = response.payloadLabel(),
            let apiFailure = Action.Failure.APIFailure(rawValue: label),
            apiFailure.statusCode == response.httpStatus {
            action.fail(with: .api(apiFailure))
        } else {
            action.fail(with: .unknown)
        }
    }
}
