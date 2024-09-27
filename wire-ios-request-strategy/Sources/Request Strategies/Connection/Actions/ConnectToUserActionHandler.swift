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

class ConnectToUserActionHandler: ActionHandler<ConnectToUserAction> {
    // MARK: Internal

    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    override func request(
        for action: ActionHandler<ConnectToUserAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            nonFederatedRequest(for: action, apiVersion: apiVersion)
        case .v1,
             .v2,
             .v3,
             .v4,
             .v5,
             .v6:
            federatedRequest(for: action, apiVersion: apiVersion)
        }
    }

    func nonFederatedRequest(
        for action: ActionHandler<ConnectToUserAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        let payload = Payload.ConnectionRequest(userID: action.userID, name: "default")

        guard
            apiVersion == .v0,
            let payloadData = payload.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            Logging.network.error("Can't create request for connection request")
            return nil
        }

        return ZMTransportRequest(
            path: "/connections",
            method: .post,
            payload: payloadAsString as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    func federatedRequest(
        for action: ActionHandler<ConnectToUserAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        let domain =
            if let domain = action.domain, !domain.isEmpty {
                domain
            } else {
                BackendInfo.domain
            }
        guard apiVersion > .v0, let domain else {
            Logging.network.error("Can't create request for connection request")
            return nil
        }

        return ZMTransportRequest(
            path: "/connections/\(domain)/\(action.userID.transportString())",
            method: .post,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: ActionHandler<ConnectToUserAction>.Action) {
        var action = action

        guard response.result == .success else {
            guard let failure = Payload.ResponseFailure(response, decoder: decoder) else {
                action.notifyResult(.failure(.unknown))
                return
            }

            switch (failure.code, failure.label) {
            case (403, .noIdentity):
                action.notifyResult(.failure(.noIdentity))
            case (403, .missingLegalholdConsent):
                action.notifyResult(.failure(.missingLegalholdConsent))
            case (403, .connectionLimit):
                action.notifyResult(.failure(.connectionLimitReached))
            case (422, .federationDenied):
                action.notifyResult(.failure(.federationDenied))
            default:
                action.notifyResult(.failure(.unknown))
            }

            return
        }

        if let connection = Payload.Connection(response, decoder: decoder) {
            processor.updateOrCreateConnection(
                from: connection,
                in: context
            )
            context.saveOrRollback()
        }

        action.notifyResult(.success(()))
    }

    // MARK: Private

    private let processor = ConnectionPayloadProcessor()
}
