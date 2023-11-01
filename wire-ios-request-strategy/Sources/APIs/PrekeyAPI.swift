////
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

protocol PrekeyAPI {

    func fetchPrekeys(for clients: Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError>

}

extension Payload.PrekeyByUserID {
    func toPrekeyByQualifiedUserID(domain: String) -> Payload.PrekeyByQualifiedUserID {
        [domain: self]
    }
}

class PrekeyAPIV0: PrekeyAPI {

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    open var apiVersion: APIVersion {
        return .v0
    }

    let httpClient: HttpClient
    let defaultEncoder = JSONEncoder.defaultEncoder

    func fetchPrekeys(for clients: Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError> {
        guard
            let payloadData = clients.clientListByUserID.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return .failure(NetworkError.errorEncodingRequest)
        }

        let request = ZMTransportRequest(path: "/users/prekeys",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?,
                                         apiVersion: apiVersion.rawValue)

        let response = await httpClient.send(request)
        let result: Swift.Result<Payload.PrekeyByUserID, NetworkError> = mapResponse(response)

        return result.map { payload in
            payload.toPrekeyByQualifiedUserID(domain: "")
        }
    }
}

class PrekeyAPIV1: PrekeyAPIV0 {
    override var apiVersion: APIVersion {
        return .v1
    }

    override func fetchPrekeys(for clients: Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError> {
        guard
            let payloadData = clients.clientListByDomain.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return .failure(NetworkError.errorEncodingRequest)
        }

        let request = ZMTransportRequest(path: "/users/list-prekeys",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?,
                                         apiVersion: apiVersion.rawValue)

        let response = await httpClient.send(request)
        return mapResponse(response)
    }
}

class PrekeyAPIV2: PrekeyAPIV1 {
    override var apiVersion: APIVersion {
        return .v2
    }
}

class PrekeyAPIV3: PrekeyAPIV2 {
    override var apiVersion: APIVersion {
        return .v3
    }
}

class PrekeyAPIV4: PrekeyAPIV3 {
    override var apiVersion: APIVersion {
        return .v4
    }

    override func fetchPrekeys(for clients: Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError> {
        guard
            let payloadData = clients.clientListByDomain.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return .failure(NetworkError.errorEncodingRequest)
        }

        let request = ZMTransportRequest(path: "/users/list-prekeys",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?,
                                         apiVersion: apiVersion.rawValue)
        let response = await httpClient.send(request)

        let result: Swift.Result<Payload.PrekeyByQualifiedUserIDV4, NetworkError> = mapResponse(response)
        return result.map({ $0.prekeyByQualifiedUserID })
    }
}

class PrekeyAPIV5: PrekeyAPIV4 {
    override var apiVersion: APIVersion {
        return .v5
    }
}

extension Collection where Element == QualifiedClientID {

    var clientListByUserID: Payload.ClientListByUserID {

        let initial: Payload.ClientListByUserID = [:]

        return self.reduce(into: initial) { (result, client) in
            result[client.userID.transportString(), default: []].append(client.clientID)
        }
    }

    var clientListByDomain: Payload.ClientListByQualifiedUserID {
        let initial: Payload.ClientListByQualifiedUserID = [:]

        return self.reduce(into: initial) { (result, client) in
            result[client.domain, default: Payload.ClientListByUserID()][client.userID.transportString(), default: []].append(client.clientID)
        }
    }

}
