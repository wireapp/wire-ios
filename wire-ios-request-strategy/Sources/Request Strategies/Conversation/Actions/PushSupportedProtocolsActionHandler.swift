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

final class PushSupportedProtocolsActionHandler: ActionHandler<PushSupportedProtocolsAction> {
    // MARK: - Request

    override func request(
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action
        guard let transportRequest = SelfSupportedProtocolsRequestBuilder(
            apiVersion: apiVersion,
            supportedProtocols: action.supportedProtocols
        ).buildTransportRequest() else {
            action.fail(with: .requestEndpointUnavailable)
            return nil
        }

        return transportRequest
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: PushSupportedProtocolsAction
    ) {
        var action = action
        switch response.httpStatus {
        case 200:
            action.succeed()

        default:
            let error = response.errorInfo
            action.fail(with: .unknownError(code: error.status, label: error.label, message: error.message))
        }
    }
}
