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

// sourcery: AutoMockable
public protocol PrekeyAPI {
    func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID
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
        .v0
    }

    let httpClient: HttpClient
    let defaultEncoder = JSONEncoder.defaultEncoder

    func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        guard
            let payloadData = clients.clientListByUserID.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: "/users/prekeys",
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )

        let response = await httpClient.send(request)
        let result: Payload.PrekeyByUserID = try mapResponse(response)
        return result.toPrekeyByQualifiedUserID(domain: "")
    }
}

class PrekeyAPIV1: PrekeyAPIV0 {
    override var apiVersion: APIVersion {
        .v1
    }

    override func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        guard
            let payloadData = clients.clientListByDomain.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: "/users/list-prekeys",
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )

        let response = await httpClient.send(request)
        return try mapResponse(response)
    }
}

class PrekeyAPIV2: PrekeyAPIV1 {
    override var apiVersion: APIVersion {
        .v2
    }
}

class PrekeyAPIV3: PrekeyAPIV2 {
    override var apiVersion: APIVersion {
        .v3
    }
}

class PrekeyAPIV4: PrekeyAPIV3 {
    override var apiVersion: APIVersion {
        .v4
    }

    override func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        guard
            let payloadData = clients.clientListByDomain.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: "/users/list-prekeys",
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )
        let response = await httpClient.send(request)

        let result: Payload.PrekeyByQualifiedUserIDV4 = try mapResponse(response)
        return result.prekeyByQualifiedUserID
    }
}

class PrekeyAPIV5: PrekeyAPIV4 {
    override var apiVersion: APIVersion {
        .v5
    }
}

class PrekeyAPIV6: PrekeyAPIV5 {
    override var apiVersion: APIVersion {
        .v6
    }
}

extension Collection<QualifiedClientID> {
    var clientListByUserID: Payload.ClientListByUserID {
        let initial: Payload.ClientListByUserID = [:]

        return reduce(into: initial) { result, client in
            result[client.userID.transportString(), default: []].append(client.clientID)
        }
    }

    var clientListByDomain: Payload.ClientListByQualifiedUserID {
        let initial: Payload.ClientListByQualifiedUserID = [:]

        return reduce(into: initial) { result, client in
            result[client.domain, default: Payload.ClientListByUserID()][client.userID.transportString(), default: []]
                .append(client.clientID)
        }
    }
}
