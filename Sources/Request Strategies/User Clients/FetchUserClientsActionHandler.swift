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
import WireDataModel

final class FetchUserClientsActionHandler: ActionHandler<FetchUserClientsAction> {

    // MARK: - Request

    struct RequestPayload: Codable, Equatable {

        let qualified_users: Set<QualifiedID>

    }

    override func request(
        for action: FetchUserClientsAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        switch apiVersion {
        case .v0:
            action.fail(with: .endpointUnavailable)
            return nil

        case .v1, .v2:
            guard
                let payloadData = RequestPayload(qualified_users: action.userIDs).payloadData(),
                let payloadString = String(bytes: payloadData, encoding: .utf8)
            else {
                action.fail(with: .failedToEncodeRequestPayload)
                return nil
            }

            return ZMTransportRequest(
                path: "/users/list-clients",
                method: .methodPOST,
                payload: payloadString as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    // MARK: - Response

    struct ResponsePayload: Codable, Equatable {

        let qualified_user_map: Payload.UserClientByDomain

    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: FetchUserClientsAction
    ) {
        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            return
        }

        var action = action

        switch apiVersion {
        case .v0:
            return

        case .v1, .v2:
            switch response.httpStatus {
            case 200:
                guard let rawData = response.rawData else {
                    action.fail(with: .missingResponsePayload)
                    return
                }

                guard let payload = ResponsePayload(rawData) else {
                    action.fail(with: .failedToDecodeResponsePayload)
                    return
                }

                var result = FetchUserClientsAction.Result()

                for (domain, users) in payload.qualified_user_map {
                    for (userID, clients) in users {
                        guard let userID = UUID(uuidString: userID) else {
                            continue
                        }

                        result.formUnion(clients.map { client in
                            QualifiedClientID(
                                userID: userID,
                                domain: domain,
                                clientID: client.id
                            )
                        })
                    }
                }

                action.succeed(with: result)

            case 400:
                action.fail(with: .malformdRequestPayload)

            default:
                let errorInfo = response.errorInfo
                action.fail(with: .unknown(status: errorInfo.status, label: errorInfo.label, message: errorInfo.message))
            }

        }
    }

}
