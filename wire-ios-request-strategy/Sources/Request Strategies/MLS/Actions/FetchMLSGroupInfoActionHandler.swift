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

class FetchMLSConversationGroupInfoActionHandler: BaseFetchMLSGroupInfoActionHandler<FetchMLSConversationGroupInfoAction> {

    override func request(for action: FetchMLSConversationGroupInfoAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            !action.domain.isEmpty,
            !action.conversationId.uuidString.isEmpty
        else {
            action.fail(with: .emptyParameters)
            return nil
        }

        return self.request(
            for: action,
            path: "/conversations/\(action.domain)/\(action.conversationId.transportString())/groupinfo",
            apiVersion: apiVersion,
            minRequiredAPIVersion: .v3
        )
    }
}

class FetchMLSSubconversationGroupInfoActionHandler: BaseFetchMLSGroupInfoActionHandler<FetchMLSSubconversationGroupInfoAction> {

    override func request(for action: FetchMLSSubconversationGroupInfoAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            !action.domain.isEmpty,
            !action.conversationId.uuidString.isEmpty
        else {
            action.fail(with: .emptyParameters)
            return nil
        }

        return request(
            for: action,
            path: "/conversations/\(action.domain)/\(action.conversationId.transportString())/subconversations/\(action.subgroupType)/groupinfo",
            apiVersion: apiVersion,
            minRequiredAPIVersion: .v4
        )
    }
}

class BaseFetchMLSGroupInfoActionHandler<T: BaseFetchMLSGroupInfoAction>: ActionHandler<T> {

    func request(for action: T, path: String, apiVersion: APIVersion, minRequiredAPIVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= minRequiredAPIVersion else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        return ZMTransportRequest(
            path: path,
            method: .methodGET,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: T) {
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
        case (400, "mls-not-enabled"):
            action.fail(with: .mlsNotEnabled)
        case (400, _):
            action.fail(with: .invalidParameters)
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

extension BaseFetchMLSGroupInfoActionHandler {

    // MARK: - Payload

    struct ResponsePayload: Codable {
        let groupState: Data
    }
}
