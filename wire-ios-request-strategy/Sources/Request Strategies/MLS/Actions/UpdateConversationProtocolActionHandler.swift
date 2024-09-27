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

// MARK: - UpdateConversationProtocolActionHandler

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
        let messageProtocol = action.messageProtocol.rawValue
        let path = "/conversations/\(domain)/\(conversationID)/protocol"
        let payload = ["protocol": messageProtocol] as ZMTransportData

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

        let statusCode = response.httpStatus
        let label = response.payloadLabel()
        let apiFailure = Action.Failure.APIFailure(statusCode, label)

        switch (statusCode, label, apiFailure) {
        case (200, _, _), (204, _, _):
            action.succeed()

        case let (_, _, .some(apiFailure)):
            action.fail(with: .api(apiFailure))

        case (404, _, _): // edge case, where API doesn't return a label
            action.fail(with: .api(.conversationIdOrDomainNotFound))

        case (400, _, _):
            action.fail(with: .api(.invalidBody))

        default:
            action.fail(with: .unknown)
        }
    }
}

extension UpdateConversationProtocolAction.Failure.APIFailure {
    fileprivate init?(_ statusCode: Int, _ label: String?) {
        guard let label else {
            return nil
        }
        self.init(rawValue: label)
        guard self.statusCode == statusCode else {
            return nil
        }
    }
}
