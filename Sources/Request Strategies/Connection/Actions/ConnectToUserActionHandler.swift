// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class ConnectToUserActionHandler: ActionHandler<ConnectToUserAction>, FederationAware {

    var useFederationEndpoint: Bool = false
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    override func request(for action: ActionHandler<ConnectToUserAction>.Action) -> ZMTransportRequest? {
        if useFederationEndpoint {
            return federatedRequest(for: action)
        } else {
            return nonFederatedRequest(for: action)
        }
    }

    func federatedRequest(for action: ActionHandler<ConnectToUserAction>.Action) -> ZMTransportRequest? {
        guard
            let domain  = action.domain
        else {
            Logging.network.error("Can't create request for connection request")
            return nil
        }

        return ZMTransportRequest(path: "/connections/\(domain)/\(action.userID.transportString())",
                                  method: .methodPOST,
                                  payload: nil)
    }

    func nonFederatedRequest(for action: ActionHandler<ConnectToUserAction>.Action) -> ZMTransportRequest? {
        let payload = Payload.ConnectionRequest(userID: action.userID, name: "default")

        guard
            let payloadData = payload.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            Logging.network.error("Can't create request for connection request")
            return nil
        }

        return ZMTransportRequest(path: "/connections",
                                  method: .methodPOST,
                                  payload: payloadAsString as ZMTransportData)

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
            default:
                action.notifyResult(.failure(.unknown))
            }

            return
        }

        let connection = Payload.Connection(response, decoder: decoder)
        connection?.updateOrCreate(in: context)
        context.saveOrRollback()
        action.notifyResult(.success(Void()))
    }

}
