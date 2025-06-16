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
import WireAPI

public struct StoredBackendEnvironment: Codable, Sendable {

    public let title: String
    public let endpoints: Endpoints
    public let pinnedKeys: [PinnedKey]
    public let proxySettings: ProxySettings?
    public let metadata: ResolvedBackendMetadata

    public struct Endpoints: Codable, Sendable {
        public let restAPIURL: URL
        public let websocketURL: URL
        public let blacklistURL: URL
        public let teamsURL: URL
        public let accountsURL: URL
        public let websiteURL: URL
        public let countlyURL: URL?
    }

    public struct ResolvedBackendMetadata: Codable, Sendable {
        public let apiVersion: APIVersion
        public let domain: String
        public let isFederationEnabled: Bool
    }

    public enum ProxySettings: Codable, Sendable {
        case unauthenticated(host: String, port: Int)
        case authenticated(host: String, port: Int, username: String, password: String)
    }

    public struct PinnedKey: Codable, Sendable {
        public enum Host: Codable, Sendable {
            case endsWith(String)
            case equals(String)
        }

        public let keyDataBase64: String
        public let hosts: [Host]
    }

    public enum APIVersion: UInt, Codable, Sendable {
        case v0
        case v1
        case v2
        case v3
        case v4
        case v5
        case v6
        case v7
        case v8
    }
}

// MARK: - To Stored

extension BackendEnvironment2 {
    func toStored() -> StoredBackendEnvironment {
        .init(
            title: title,
            endpoints: endpoints.toStored(),
            pinnedKeys: pinnedKeys.compactMap { $0.toStored() },
            proxySettings: proxySettings?.toStored(),
            metadata: metadata.toStored()
        )
    }
}

extension BackendEnvironment2.Endpoints {
    func toStored() -> StoredBackendEnvironment.Endpoints {
        .init(
            restAPIURL: restAPIURL,
            websocketURL: websocketURL,
            blacklistURL: blacklistURL,
            teamsURL: teamsURL,
            accountsURL: accountsURL,
            websiteURL: websiteURL,
            countlyURL: countlyURL
        )
    }
}

extension BackendEnvironment2.ResolvedBackendMetadata {
    func toStored() -> StoredBackendEnvironment.ResolvedBackendMetadata {
        .init(
            apiVersion: apiVersion.toStored(),
            domain: domain,
            isFederationEnabled: isFederationEnabled
        )
    }
}

extension WireAPI.APIVersion {
    func toStored() -> StoredBackendEnvironment.APIVersion {
        switch self {
        case .v0: .v0
        case .v1: .v1
        case .v2: .v2
        case .v3: .v3
        case .v4: .v4
        case .v5: .v5
        case .v6: .v6
        case .v7: .v7
        case .v8: .v8
        }
    }
}

extension ProxySettings {
    func toStored() -> StoredBackendEnvironment.ProxySettings {
        switch self {
        case let .unauthenticated(host, port):
            .unauthenticated(host: host, port: port)
        case let .authenticated(host, port, username, password):
            .authenticated(host: host, port: port, username: username, password: password)
        }
    }
}

extension PinnedKey {
    func toStored() -> StoredBackendEnvironment.PinnedKey? {
        guard let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? else { return nil }
        return .init(
            keyDataBase64: keyData.base64EncodedString(),
            hosts: hosts.map { $0.toStored() }
        )
    }
}

extension PinnedKey.Host {
    func toStored() -> StoredBackendEnvironment.PinnedKey.Host {
        switch self {
        case let .endsWith(s): .endsWith(s)
        case let .equals(v): .equals(v)
        }
    }
}

// MARK: - To API

extension StoredBackendEnvironment {
    func toDomain() throws -> BackendEnvironment2 {
        BackendEnvironment2(
            title: title,
            endpoints: endpoints.toDomain(),
            pinnedKeys: try pinnedKeys.map { try $0.toDomain() },
            proxySettings: proxySettings?.toDomain(),
            metadata: metadata.toDomain()
        )
    }
}

extension StoredBackendEnvironment.Endpoints {
    func toDomain() -> BackendEnvironment2.Endpoints {
        .init(
            restAPIURL: restAPIURL,
            websocketURL: websocketURL,
            blacklistURL: blacklistURL,
            teamsURL: teamsURL,
            accountsURL: accountsURL,
            websiteURL: websiteURL,
            countlyURL: countlyURL
        )
    }
}

extension StoredBackendEnvironment.ResolvedBackendMetadata {
    func toDomain() -> BackendEnvironment2.ResolvedBackendMetadata {
        .init(
            apiVersion: apiVersion.toDomain(),
            domain: domain,
            isFederationEnabled: isFederationEnabled
        )
    }
}

extension StoredBackendEnvironment.APIVersion {
    func toDomain() -> WireAPI.APIVersion {
        switch self {
        case .v0: .v0
        case .v1: .v1
        case .v2: .v2
        case .v3: .v3
        case .v4: .v4
        case .v5: .v5
        case .v6: .v6
        case .v7: .v7
        case .v8: .v8
        }
    }
}

extension StoredBackendEnvironment.ProxySettings {
    func toDomain() -> ProxySettings {
        switch self {
        case let .unauthenticated(host, port):
            .unauthenticated(host: host, port: port)
        case let .authenticated(host, port, username, password):
            .authenticated(host: host, port: port, username: username, password: password)
        }
    }
}

extension StoredBackendEnvironment.PinnedKey {
    func toDomain() throws -> PinnedKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]
        guard let keyData = Data(base64Encoded: keyDataBase64),
              let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil)
        else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Invalid base64 key data in StoredPinnedKey"
            ))
        }

        return PinnedKey(key: key, hosts: hosts.map { $0.toDomain() })
    }
}

extension StoredBackendEnvironment.PinnedKey.Host {
    func toDomain() -> PinnedKey.Host {
        switch self {
        case let .endsWith(s): .endsWith(s)
        case let .equals(v): .equals(v)
        }
    }
}
