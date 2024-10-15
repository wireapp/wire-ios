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

final class DeleteSubgroupActionHandler: ActionHandler<DeleteSubgroupAction> {

    // MARK: - Request

    override func request(
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= .v4 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        let domain = action.domain
        let conversationID = action.conversationID.transportString()
        let subgroupType = action.subgroupType.rawValue

        guard
            !domain.isEmpty,
            !conversationID.isEmpty,
            !subgroupType.isEmpty
        else {
            action.fail(with: .invalidParameters)
            return nil
        }
        var payload: [String: Any] = [:]
        payload["epoch"] = action.epoch
        payload["group_id"] = action.groupID.data.base64EncodedString()

        return ZMTransportRequest(
            path: "/conversations/\(domain)/\(conversationID)/subconversations/\(subgroupType)",
            method: .delete,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: Action
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            action.succeed()

        case (400, "mls-not-enabled"):
            action.fail(with: .mlsNotEnabled)

        case (400, _):
            action.fail(with: .invalidParameters)

        case (403, "access-denied"):
            action.fail(with: .accessDenied)

        case (404, "no-conversation"):
            action.fail(with: .noConversation)

        case (409, "mls-stale-message"):
            action.fail(with: .mlsStaleMessage)

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
