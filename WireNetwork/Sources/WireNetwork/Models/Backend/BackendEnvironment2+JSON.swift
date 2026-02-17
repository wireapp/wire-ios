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

public extension BackendEnvironment2 {

    static func fromJSON(
        _ string: String,
        environmentType: EnvironmentType
    ) throws -> BackendEnvironment2 {
        try fromJSON(
            Data(string.utf8),
            environmentType: environmentType
        )
    }

    static func fromJSON(
        _ data: Data,
        environmentType: EnvironmentType
    ) throws -> BackendEnvironment2 {
        let json = try JSONDecoder().decode(
            BackendEnvironmentJSON.self,
            from: data
        )

        let endpoints = Endpoints(
            restAPIURL: json.endpoints.backendURL,
            websocketURL: json.endpoints.backendWSURL,
            blacklistURL: json.endpoints.blackListURL,
            teamsURL: json.endpoints.teamsURL,
            accountsURL: json.endpoints.accountsURL,
            websiteURL: json.endpoints.websiteURL,
            countlyURL: json.endpoints.countlyURL
        )

        var pinnedKeys = [PinnedKey]()
        if let pinnedKeysJSON = json.pinnedKeys {
            do {
                pinnedKeys = try pinnedKeysJSON.map { pinnedKey in
                    try PinnedKey(
                        rawKey: pinnedKey.certificateKey,
                        hosts: pinnedKey.hosts.map { host in
                            switch host.rule {
                            case .endsWith:
                                .endsWith(host.value)
                            case .equals:
                                .equals(host.value)
                            }
                        }
                    )
                }
            } catch {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [BackendEnvironmentJSON.CodingKeys.pinnedKeys],
                        debugDescription: "invalid certificate key",
                        underlyingError: error
                    )
                )
            }

        }

        let proxyConfig = json.apiProxy.map {
            ProxyConfig(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        let config = Config(
            endpoints: endpoints,
            pinnedKeys: pinnedKeys,
            proxyConfig: proxyConfig
        )

        return BackendEnvironment2(
            title: json.title,
            environmentType: environmentType,
            config: config
        )
    }

}

private struct BackendEnvironmentJSON: Decodable {

    let title: String
    let endpoints: Endpoints
    let apiProxy: APIProxy?
    let pinnedKeys: [PinnedKey]?

    enum CodingKeys: String, CodingKey {

        case title
        case endpoints
        case apiProxy
        case pinnedKeys

    }

    struct Endpoints: Decodable {

        let backendURL: URL
        let backendWSURL: URL
        let blackListURL: URL
        let teamsURL: URL
        let accountsURL: URL
        let websiteURL: URL
        let countlyURL: URL?

    }

    struct APIProxy: Decodable {

        let host: String
        let port: Int
        let needsAuthentication: Bool

    }

    struct PinnedKey: Decodable {

        let certificateKey: Data
        let hosts: [Host]

        struct Host: Decodable {

            let rule: Rule
            let value: String

            enum Rule: String, Decodable {
                case endsWith = "ends_with"
                case equals
            }

        }

    }

}
