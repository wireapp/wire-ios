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

class UpdateConnectionActionHandler: ActionHandler<UpdateConnectionAction> {
    // MARK: Internal

    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    override func request(for action: UpdateConnectionAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            v0Request(for: action)

        case .v1,
             .v2,
             .v3,
             .v4,
             .v5,
             .v6:
            v1Request(for: action)
        }
    }

    override func handleResponse(_ response: ZMTransportResponse, action: UpdateConnectionAction) {
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
            case (403, .notConnected):
                action.notifyResult(.failure(.notConnected))
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

    private func v0Request(for action: UpdateConnectionAction) -> ZMTransportRequest? {
        guard
            let connection = ZMConnection.existingObject(for: action.connectionID, in: context),
            let userID = connection.to.remoteIdentifier?.transportString(),
            let payload = payload(from: action)
        else {
            Logging.network.error("Can't create request to update connection status")
            return nil
        }

        return ZMTransportRequest(
            path: "/connections/\(userID)",
            method: .put,
            payload: payload,
            apiVersion: 0
        )
    }

    private func v1Request(for action: UpdateConnectionAction) -> ZMTransportRequest? {
        guard
            let connection = ZMConnection.existingObject(for: action.connectionID, in: context),
            let qualifiedID = connection.to.qualifiedID,
            let payload = payload(from: action)
        else {
            Logging.network.error("Can't create request to update connection status")
            return nil
        }

        return ZMTransportRequest(
            path: "/connections/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
            method: .put,
            payload: payload,
            apiVersion: 1
        )
    }

    private func payload(from action: UpdateConnectionAction) -> ZMTransportData? {
        guard
            let status = Payload.ConnectionStatus(action.newStatus)
        else {
            Logging.network.error("Can't create request to update connection status")
            return nil
        }

        let payload = Payload.ConnectionUpdate(status: status)

        guard
            let payloadData = payload.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            Logging.network.error("Can't create payload to update connection status")
            return nil
        }

        return payloadAsString as ZMTransportData
    }
}
