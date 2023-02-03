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

class ClaimMLSKeyPackageActionHandler: ActionHandler<ClaimMLSKeyPackageAction> {

    // MARK: - Methods

    override func request(for action: ClaimMLSKeyPackageAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard apiVersion > .v0 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        guard let domain = action.domain?.nilIfEmpty ?? BackendInfo.domain else {
            action.fail(with: .missingDomain)
            return nil
        }

        let path = "/mls/key-packages/claim/\(domain)/\(action.userId.transportString())"

        var payload: ZMTransportData?
        if let skipOwn = action.excludedSelfClientId, !skipOwn.isEmpty {
            payload = ["skip_own": skipOwn] as ZMTransportData
        }

        return ZMTransportRequest(
            path: path,
            method: .methodPOST,
            payload: payload,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: ClaimMLSKeyPackageAction) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let data = response.rawData,
                let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data)
            else {
                return action.fail(with: .malformedResponse)
            }

            // The action shouldn't return a key package for the self client,
            // but it does for some reason. As a temporary workaround, just
            // filter it out here.
            let keyPackagesExcludingSelfClient = payload.keyPackages.filter {
                $0.client != action.excludedSelfClientId
            }

            action.succeed(with: keyPackagesExcludingSelfClient)

        case 400:
            action.fail(with: .invalidSelfClientId)

        case 404:
            action.fail(with: .userOrDomainNotFound)

        default:
            action.fail(with: .unknown(status: response.httpStatus))
        }
    }
}

extension ClaimMLSKeyPackageActionHandler {

    // MARK: - Payload

    struct ResponsePayload: Codable {
        let keyPackages: [KeyPackage]

        enum CodingKeys: String, CodingKey {
            case keyPackages = "key_packages"
        }
    }

}
