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

class CountSelfMLSKeyPackagesActionHandler: ActionHandler<CountSelfMLSKeyPackagesAction> {

    // MARK: - Methods

    override func request(
        for action: ActionHandler<CountSelfMLSKeyPackagesAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        var action = action

        guard apiVersion > .v0 else {
            action.notifyResult(.failure(.endpointNotAvailable))
            return nil
        }

        guard !action.clientID.isEmpty else {
            action.notifyResult(.failure(.invalidClientID))
            return nil
        }

        return ZMTransportRequest(
            path: "/mls/key-package/self/\(action.clientID)/count",
            method: .methodGET,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: ActionHandler<CountSelfMLSKeyPackagesAction>.Action
    ) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard let data = response.rawData,
                  let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data)
            else {
                action.notifyResult(.failure(.malformedResponse))
                return
            }

            action.notifyResult(.success(payload.count))

        case 404:
            action.notifyResult(.failure(.clientNotFound))

        default:
            action.notifyResult(.failure(.unknown(status: response.httpStatus)))
        }
    }
}

extension CountSelfMLSKeyPackagesActionHandler {

    // MARK: - Payload

    struct ResponsePayload: Codable {
        let count: Int
    }
}
