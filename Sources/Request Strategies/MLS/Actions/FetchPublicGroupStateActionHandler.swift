//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport
import WireDataModel

class FetchPublicGroupStateActionHandler: ActionHandler<FetchPublicGroupStateAction> {

    // MARK: - Methods

    override func request(for action: FetchPublicGroupStateAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard apiVersion > .v1 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        guard
            !action.domain.isEmpty,
            !action.conversationId.uuidString.isEmpty
        else {
            action.fail(with: .emptyParameters)
            return nil
        }

        return ZMTransportRequest(
            path: "/conversations/\(action.domain)/\(action.conversationId.transportString())/groupinfo",
            method: .methodGET,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: FetchPublicGroupStateAction) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let data = response.rawData,
                let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data)
            else {
                action.fail(with: .malformedResponse)
                return
            }
            action.succeed(with: payload.groupState)
        case (404, "mls-missing-group-info"):
            action.fail(with: .missingGroupInfo)
        case (404, "no-conversation"):
            action.fail(with: .noConversation)
        case (404, _):
            action.fail(with: .conversationIdOrDomainNotFound)
        default:
            let errorInfo = response.errorInfo
            action.fail(with: .unknown(
                status: response.httpStatus,
                label: errorInfo.label,
                message: errorInfo.message
            ))
        }
    }
}

extension FetchPublicGroupStateActionHandler {

    // MARK: - Payload

    struct ResponsePayload: Codable {
        let groupState: Data
    }
}
