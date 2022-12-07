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

class FetchBackendMLSPublicKeysActionHandler: ActionHandler<FetchBackendMLSPublicKeysAction> {

    // MARK: - Request

    override func request(
        for action: FetchBackendMLSPublicKeysAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0, .v1:
            var action = action
            action.fail(with: .endpointUnavailable)
            return nil

        case .v2, .v3:
            return ZMTransportRequest(
                path: "/mls/public-keys",
                method: .methodGET,
                payload: nil,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    // MARK: - Response

    struct ResponsePayload: Codable, Equatable {

        let removal: MLSKeys

        struct MLSKeys: Codable, Equatable {

            let ed25519: String?

        }

    }

    override func handleResponse(_ response: ZMTransportResponse, action: FetchBackendMLSPublicKeysAction) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let data = response.rawData,
                let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data)
            else {
                return action.fail(with: .malformedResponse)
            }

            let ed25519RemovalKey = payload.removal.ed25519
                .flatMap(\.base64EncodedBytes)
                .map(\.data)

            action.succeed(with: Action.Result(removal: .init(ed25519: ed25519RemovalKey)))

        default:
            let error = response.errorInfo
            action.fail(with: .unknown(status: error.status, label: error.label, message: error.message))
        }
    }

}
