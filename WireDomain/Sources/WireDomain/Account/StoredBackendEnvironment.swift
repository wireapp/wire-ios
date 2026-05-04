//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireNetwork

struct StoredBackendEnvironment: Codable, Sendable {

    let title: String
    let environmentType: EnvironmentType
    let endpoints: Endpoints
    let pinnedKeys: [PinnedKey]
    let proxyConfig: ProxyConfig?

    enum EnvironmentType: Codable, Sendable {
        case `default`
        case staging
        case anta
        case bella
        case chala
        case diya
        case elna
        case foma
        case custom(url: URL)
    }

    struct Endpoints: Codable, Sendable {
        let restAPIURL: URL
        let websocketURL: URL
        let blacklistURL: URL
        let teamsURL: URL
        let accountsURL: URL
        let websiteURL: URL
        let countlyURL: URL?
    }

    struct ProxyConfig: Codable, Sendable {
        let host: String
        let port: Int
        let needsAuthentication: Bool
    }

    struct PinnedKey: Codable, Sendable {
        enum Host: Codable, Sendable {
            case endsWith(String)
            case equals(String)
        }

        let keyDataBase64: String
        let hosts: [Host]
    }

}

// MARK: - To Stored

extension BackendEnvironment2 {
    func toStored() -> StoredBackendEnvironment {
        .init(
            title: title,
            environmentType: environmentType.toStored(),
            endpoints: config.endpoints.toStored(),
            pinnedKeys: config.pinnedKeys.compactMap { $0.toStored() },
            proxyConfig: config.proxyConfig?.toStored(),
        )
    }
}

extension BackendEnvironment2.EnvironmentType {
    func toStored() -> StoredBackendEnvironment.EnvironmentType {
        switch self {
        case .default:
            .default
        case .staging:
            .staging
        case .anta:
            .anta
        case .bella:
            .bella
        case .chala:
            .chala
        case .diya:
            .diya
        case .elna:
            .elna
        case .foma:
            .foma
        case let .custom(url):
            .custom(url: url)
        }
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

extension BackendEnvironment2.ProxyConfig {
    func toStored() -> StoredBackendEnvironment.ProxyConfig {
        .init(
            host: host,
            port: port,
            needsAuthentication: needsAuthentication
        )
    }
}

extension ResolvedBackendMetadata {
    func toStored() -> StoredResolvedBackendMetadata {
        .init(
            apiVersion: apiVersion.toStored(),
            domain: domain,
            isFederationEnabled: isFederationEnabled
        )
    }
}

extension WireNetwork.APIVersion {
    func toStored() -> UInt {
        rawValue
    }
}

extension PinnedKey {
    func toStored() -> StoredBackendEnvironment.PinnedKey? {
        .init(
            keyDataBase64: rawKey.base64EncodedString(),
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
            environmentType: environmentType.toDomain(),
            config: BackendEnvironment2.Config(
                endpoints: endpoints.toDomain(),
                pinnedKeys: try pinnedKeys.map { try $0.toDomain() },
                proxyConfig: proxyConfig?.toDomain()
            )
        )
    }
}

extension StoredBackendEnvironment.EnvironmentType {
    func toDomain() -> BackendEnvironment2.EnvironmentType {
        switch self {
        case .default:
            .default
        case .staging:
            .staging
        case .anta:
            .anta
        case .bella:
            .bella
        case .chala:
            .chala
        case .diya:
            .diya
        case .elna:
            .elna
        case .foma:
            .foma
        case let .custom(url):
            .custom(url: url)
        }
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

extension StoredResolvedBackendMetadata {
    func toDomain() throws -> ResolvedBackendMetadata {
        guard let apiVersion = APIVersion(rawValue: apiVersion) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.apiVersion],
                    debugDescription: "Stored version \(apiVersion)"
                )
            )
        }

        return ResolvedBackendMetadata(
            apiVersion: apiVersion,
            domain: domain,
            isFederationEnabled: isFederationEnabled
        )
    }
}

extension StoredBackendEnvironment.ProxyConfig {
    func toDomain() -> BackendEnvironment2.ProxyConfig {
        .init(
            host: host,
            port: port,
            needsAuthentication: needsAuthentication
        )
    }
}

extension StoredBackendEnvironment.PinnedKey {
    func toDomain() throws -> PinnedKey {
        guard let rawKey = Data(base64Encoded: keyDataBase64) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Invalid base64 key data in StoredPinnedKey"
            ))
        }

        return try .init(
            rawKey: rawKey,
            hosts: hosts.map { $0.toDomain() }
        )
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

struct StoredResolvedBackendMetadata: Codable, Sendable {

    let apiVersion: UInt
    let domain: String
    let isFederationEnabled: Bool

}
