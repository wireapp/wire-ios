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

import Foundation
import WireDataModel

final class FetchSupportedProtocolsActionHandler: ActionHandler<FetchSupportedProtocolsAction> {

    // MARK: - Request

    override func request(
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        let domain = action.userID.domain
        let id = action.userID.uuid.transportString()

        guard
            !domain.isEmpty,
            !id.isEmpty
        else {
            action.fail(with: .invalidParameters)
            return nil
        }

        return ZMTransportRequest(
            path: "/users/\(domain)/\(id)/supported-protocols",
            method: .get,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: Action
    ) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let data = response.rawData,
                let payload = [String].init(data)
            else {
                action.fail(with: .invalidResponse)
                return
            }

            let result = payload.compactMap(MessageProtocol.init(rawValue:))

            guard payload.count == result.count else {
                action.fail(with: .invalidResponse)
                return
            }

            action.succeed(with: Set(result))

        case 400:
            action.fail(with: .invalidParameters)

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
