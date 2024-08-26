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

final class ReplaceSelfMLSKeyPackagesActionHandler: ActionHandler<ReplaceSelfMLSKeyPackagesAction> {

    // MARK: - Methods

    override func request(for action: ReplaceSelfMLSKeyPackagesAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        guard !action.clientID.isEmpty, !action.keyPackages.isEmpty else {
            action.fail(with: .invalidParameters)
            return nil
        }

        return ZMTransportRequest(
            path: "/mls/key-packages/self/\(action.clientID)?ciphersuites=\(action.ciphersuite.rawValue)",
            method: .put,
            payload: ["key_packages": action.keyPackages] as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: ReplaceSelfMLSKeyPackagesAction) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (201, _):
            action.succeed()

        case (400, "mls-protocol-error"):
            action.fail(with: .mlsProtocolError)

        case (400, _):
            action.fail(with: .invalidBodyOrCiphersuites)

        case (403, "mls-identity-mismatch"):
            action.fail(with: .mlsIdentityMismatch)

        default:
            action.fail(with: .unknown(status: response.httpStatus))
        }
    }
}
