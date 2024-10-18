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
import WireCryptobox
import WireDataModel

enum UserClientRequestError: Error {
    case noPreKeys
    case noLastPreKey
    case clientNotRegistered
}
// swiftlint:disable:next todo_requires_jira_link
// TODO: when we should update last pre key or signaling keys?

extension UserClientRequestFactory {

    public func registerClientRequest(
        _ client: UserClient,
        credentials: UserEmailCredentials?,
        cookieLabel: String,
        prekeys: [IdPrekeyTuple],
        lastRestortPrekey: IdPrekeyTuple,
        apiVersion: APIVersion
    ) throws -> ZMUpstreamRequest {

        guard let preKeysRangeMax = prekeys.map(\.id).max() else {
            throw UserClientRequestError.noPreKeys
        }

        let preKeysPayloadData = payloadForPreKeys(prekeys)
        let lastPreKeyPayloadData = payloadForLastPreKey(lastRestortPrekey)
        let (signalingKeysPayloadData, signalingKeys) = payloadForSignalingKeys()

        var payload: [String: Any] = [
            "type": client.type.rawValue,
            "label": (client.label ?? ""),
            "model": (client.model ?? ""),
            "class": (client.deviceClass?.rawValue ?? DeviceClass.phone.rawValue),
            "lastkey": lastPreKeyPayloadData,
            "prekeys": preKeysPayloadData,
            "sigkeys": signalingKeysPayloadData,
            "cookie": cookieLabel
        ]

        if let password = credentials?.password {
            payload["password"] = password
        }

        if let verificationCode = credentials?.emailVerificationCode {
            payload["verification_code"] = verificationCode
        }

        let request = ZMTransportRequest(path: "/clients", method: ZMTransportRequestMethod.post, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(storeMaxRangeID(client, maxRangeID: preKeysRangeMax))
        request.add(storeAPSSignalingKeys(client, signalingKeys: signalingKeys))

        let upstreamRequest = ZMUpstreamRequest(transportRequest: request)
        return upstreamRequest!
    }

    func storeMaxRangeID(_ client: UserClient, maxRangeID: UInt16) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client else { return }
            if response.result == .success {
                client.preKeysRangeMax = Int64(maxRangeID)
            }
        })
        return completionHandler
    }

    func storeAPSSignalingKeys(_ client: UserClient, signalingKeys: SignalingKeys) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client else { return }
            if response.result == .success {
                client.apsDecryptionKey = signalingKeys.decryptionKey
                client.apsVerificationKey = signalingKeys.verificationKey
                client.needsToUploadSignalingKeys = false
            }
        })
        return completionHandler
    }

    func storeCapabilitiesHandler(_ client: UserClient) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client else { return }
            if response.result == .success {
                client.needsToUpdateCapabilities = false
            }
        })
        return completionHandler
    }

    internal func payloadForPreKeys(_ prekeys: [IdPrekeyTuple]) -> [[String: Any]] {
        return prekeys.map {
            ["key": $0.prekey, "id": NSNumber(value: $0.id)]
        }
    }

    internal func payloadForLastPreKey(_ lastResortPrekey: IdPrekeyTuple) -> [String: Any] {
        return [
            "key": lastResortPrekey.prekey,
            "id": NSNumber(value: lastResortPrekey.id)
        ]
    }

    internal func payloadForSignalingKeys() -> (payload: [String: String], signalingKeys: SignalingKeys) {
        let signalingKeys = APSSignalingKeysStore.createKeys()
        let payload = ["enckey": signalingKeys.decryptionKey.base64String(), "mackey": signalingKeys.verificationKey.base64String()]
        return (payload, signalingKeys)
    }

    public func updateClientPreKeysRequest(_ client: UserClient, prekeys: [IdPrekeyTuple], apiVersion: APIVersion) throws -> ZMUpstreamRequest {
        guard let remoteIdentifier = client.remoteIdentifier else {
            throw UserClientRequestError.clientNotRegistered
        }
        guard let preKeysRangeMax = prekeys.map(\.id).max() else {
            throw UserClientRequestError.noPreKeys
        }

        let preKeysPayloadData = payloadForPreKeys(prekeys)
        let payload: [String: Any] = [
            "prekeys": preKeysPayloadData
        ]
        let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.put, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(storeMaxRangeID(client, maxRangeID: preKeysRangeMax))

        let userClientNumberOfKeysRemainingKeySet: Set<String> = [ZMUserClientNumberOfKeysRemainingKey]
        return ZMUpstreamRequest(keys: userClientNumberOfKeysRemainingKeySet, transportRequest: request, userInfo: nil)
    }

    public func updateClientSignalingKeysRequest(_ client: UserClient, apiVersion: APIVersion) throws -> ZMUpstreamRequest {
        if let remoteIdentifier = client.remoteIdentifier {
            let (signalingKeysPayloadData, signalingKeys) = payloadForSignalingKeys()
            let payload: [String: Any] = [
                "sigkeys": signalingKeysPayloadData,
                "prekeys": [] // NOTE backend always expects 'prekeys' to be present atm
            ]
            let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.put, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
            request.add(storeAPSSignalingKeys(client, signalingKeys: signalingKeys))

            let userClientNeedsToUpdateSignalingKeysKeySet: Set<String> = [ZMUserClientNeedsToUpdateSignalingKeysKey]
            return ZMUpstreamRequest(keys: userClientNeedsToUpdateSignalingKeysKeySet, transportRequest: request, userInfo: nil)
        }
        throw UserClientRequestError.clientNotRegistered
    }

    func updateClientMLSPublicKeysRequest(
        _ client: UserClient,
        apiVersion: APIVersion
    ) throws -> ZMUpstreamRequest? {
        guard let clientID = client.remoteIdentifier else {
            throw UserClientRequestError.clientNotRegistered
        }

        let payload = MLSPublicKeyUploadPayload(keys: client.mlsPublicKeys)
        let payloadData = try JSONEncoder().encode(payload)
        let payloadDataString = String(decoding: payloadData, as: UTF8.self)

        let request = ZMTransportRequest(
            path: "/clients/\(clientID)",
            method: .put,
            payload: payloadDataString as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )

        return ZMUpstreamRequest(
            keys: Set([UserClient.needsToUploadMLSPublicKeysKey]),
            transportRequest: request
        )
    }

    public func updateClientCapabilitiesRequest(_ client: UserClient, apiVersion: APIVersion) throws -> ZMUpstreamRequest? {
        guard let remoteIdentifier = client.remoteIdentifier else {
            throw UserClientRequestError.clientNotRegistered
        }
        let payload: [String: Any] = [
            "capabilities": ["legalhold-implicit-consent"]
        ]
        let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.put, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(storeCapabilitiesHandler(client))

        let userClientNeedsToUpdateCapabilitiesKeySet: Set<String> = [ZMUserClientNeedsToUpdateCapabilitiesKey]
        return ZMUpstreamRequest(keys: userClientNeedsToUpdateCapabilitiesKeySet, transportRequest: request, userInfo: nil)
    }

    /// Password needs to be set
    public func deleteClientRequest(_ client: UserClient, credentials: UserEmailCredentials?, apiVersion: APIVersion) -> ZMUpstreamRequest {
        let payload: [AnyHashable: Any]

        if let credentials,
            let email = credentials.email,
            let password = credentials.password {
            payload = [
                "email": email,
                "password": password
            ]
        } else {
            payload = [:]
        }

        let request = ZMTransportRequest(path: "/clients/\(client.remoteIdentifier!)", method: ZMTransportRequestMethod.delete, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        let userClientMarkedToDeleteKeySet: Set<String> = [ZMUserClientMarkedToDeleteKey]
        return ZMUpstreamRequest(keys: userClientMarkedToDeleteKeySet, transportRequest: request)
    }

    public func fetchClientsRequest(apiVersion: APIVersion) -> ZMTransportRequest! {
        return ZMTransportRequest(getFromPath: "/clients", apiVersion: apiVersion.rawValue)
    }

}

private struct MLSPublicKeyUploadPayload: Encodable {

    enum CodingKeys: String, CodingKey {

        case keys = "mls_public_keys"

    }

    let keys: UserClient.MLSPublicKeys

}
