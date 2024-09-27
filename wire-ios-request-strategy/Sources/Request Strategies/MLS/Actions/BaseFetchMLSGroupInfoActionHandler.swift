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
import WireTransport

class BaseFetchMLSGroupInfoActionHandler<T: BaseFetchMLSGroupInfoAction>: ActionHandler<T> {
    func request(
        for action: T,
        path: String,
        apiVersion: APIVersion,
        minRequiredAPIVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= minRequiredAPIVersion else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        return ZMTransportRequest(
            path: path,
            method: .get,
            binaryData: nil,
            type: nil,
            acceptHeaderType: .messageMLS,
            contentDisposition: nil,
            shouldCompress: false,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: T) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard let data = response.rawData else {
                action.fail(with: .malformedResponse)
                return
            }

            action.succeed(with: data)

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
