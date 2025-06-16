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

import WireAPI
import Foundation

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
        case v0, v1, v2, v3, v4, v5, v6, v7, v8
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
        case .v0: return .v0
        case .v1: return .v1
        case .v2: return .v2
        case .v3: return .v3
        case .v4: return .v4
        case .v5: return .v5
        case .v6: return .v6
        case .v7: return .v7
        case .v8: return .v8
        }
    }
}

extension ProxySettings {
    func toStored() -> StoredBackendEnvironment.ProxySettings {
        switch self {
        case let .unauthenticated(host, port):
            return .unauthenticated(host: host, port: port)
        case let .authenticated(host, port, username, password):
            return .authenticated(host: host, port: port, username: username, password: password)
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
        case let .endsWith(s): return .endsWith(s)
        case let .equals(v): return .equals(v)
        }
    }
}

// MARK: - To API

extension StoredBackendEnvironment {
    func toAPI() throws -> BackendEnvironment2 {
        return BackendEnvironment2(
            title: title,
            endpoints: endpoints.toAPI(),
            pinnedKeys: try pinnedKeys.map { try $0.toAPI() },
            proxySettings: proxySettings?.toAPI(),
            metadata: metadata.toAPI()
        )
    }
}

extension StoredBackendEnvironment.Endpoints {
    func toAPI() -> BackendEnvironment2.Endpoints {
        return .init(
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
    func toAPI() -> BackendEnvironment2.ResolvedBackendMetadata {
        return .init(
            apiVersion: apiVersion.toAPI(),
            domain: domain,
            isFederationEnabled: isFederationEnabled
        )
    }
}

extension StoredBackendEnvironment.APIVersion {
    func toAPI() -> WireAPI.APIVersion {
        switch self {
        case .v0: return .v0
        case .v1: return .v1
        case .v2: return .v2
        case .v3: return .v3
        case .v4: return .v4
        case .v5: return .v5
        case .v6: return .v6
        case .v7: return .v7
        case .v8: return .v8
        }
    }
}

extension StoredBackendEnvironment.ProxySettings {
    func toAPI() -> ProxySettings {
        switch self {
        case let .unauthenticated(host, port):
            return .unauthenticated(host: host, port: port)
        case let .authenticated(host, port, username, password):
            return .authenticated(host: host, port: port, username: username, password: password)
        }
    }
}

extension StoredBackendEnvironment.PinnedKey {
    func toAPI() throws -> PinnedKey {
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
        
        return PinnedKey(key: key, hosts: hosts.map { $0.toAPI() })
    }
}

extension StoredBackendEnvironment.PinnedKey.Host {
    func toAPI() -> PinnedKey.Host {
        switch self {
        case let .endsWith(s): return .endsWith(s)
        case let .equals(v): return .equals(v)
        }
    }
}
