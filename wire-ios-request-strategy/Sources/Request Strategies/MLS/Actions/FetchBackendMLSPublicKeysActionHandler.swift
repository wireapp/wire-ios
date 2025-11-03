//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
        case .v0, .v1, .v2, .v3, .v4:
            var action = action
            action.fail(with: .endpointUnavailable)
            return nil

        case .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            return ZMTransportRequest(
                path: "/mls/public-keys",
                method: .get,
                payload: nil,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    override func handleResponse(_ response: ZMTransportResponse, action: FetchBackendMLSPublicKeysAction) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let data = response.rawData,
                let payload = try? JSONDecoder().decode(Payload.ExternalSenderKeys.self, from: data)
            else {
                return action.fail(with: .malformedResponse)
            }
            action.succeed(
                with: Action.Result(
                    removal: .init(
                        ed25519: payload.removal.ed25519?.base64DecodedData,
                        ed448: payload.removal.ed448?.base64DecodedData,
                        p256: payload.removal.p256?.base64DecodedData,
                        p384: payload.removal.p384?.base64DecodedData,
                        p521: payload.removal.p521?.base64DecodedData
                    )
                )
            )

        case (400, "mls-not-enabled"):
            action.fail(with: .mlsNotEnabled)

        default:
            let error = response.errorInfo
            action.fail(with: .unknown(status: error.status, label: error.label, message: error.message))
        }
    }

}

extension Payload {

    struct ExternalSenderKeys: Codable, Equatable {

        let removal: MLSKeys

        struct MLSKeys: Codable, Equatable {

            enum CodingKeys: String, CodingKey {
                case ed25519
                case ed448
                case p256 = "ecdsa_secp256r1_sha256"
                case p384 = "ecdsa_secp384r1_sha384"
                case p521 = "ecdsa_secp521r1_sha512"
            }

            let ed25519: String?
            let ed448: String?
            let p256: String?
            let p384: String?
            let p521: String?

        }

    }

}
