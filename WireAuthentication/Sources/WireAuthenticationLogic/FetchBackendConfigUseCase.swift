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
import WireAuthenticationAPI
import WireLogging
import WireNetwork
import WireNetworkInterface

public struct FetchBackendEnvironmentUseCase: FetchBackendEnvironmentUseCaseProtocol {

    public init() {}

    public func invoke(at configURL: URL) async throws -> BackendEnvironment2 {
        do {
            let (data, _) = try await URLSession.shared.data(from: configURL)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let payload = try decoder.decode(Payload.self, from: data)
            WireLogger.backend.info("Fetched custom configuration from \(configURL)")
            return try BackendEnvironment2(
                url: configURL,
                payload: payload
            )
        } catch let decodingError as DecodingError {
            WireLogger.backend.error("Error decoding response from \(configURL): \(decodingError)")
            throw FetchBackendConfigFailure.invalidResponse
        } catch {
            WireLogger.backend.error("Error fetching configuration from \(configURL): \(error)")
            throw error
        }
    }

}

private struct Payload: Decodable {

    let title: String
    let endpoints: Endpoints
    let apiProxy: APIProxy?
    let pinnedKeys: [TrustData]?

}

private struct Endpoints: Decodable {

    let backendURL: URL
    let backendWSURL: URL
    let blackListURL: URL
    let teamsURL: URL
    let accountsURL: URL
    let websiteURL: URL
    let countlyURL: URL?
}

private struct APIProxy: Decodable {

    let host: String
    let port: Int
    let needsAuthentication: Bool

}

private struct TrustData: Decodable {

    let certificateKey: Data
    let hosts: [Host]

}

private struct Host: Decodable {

    let rule: Rule
    let value: String

}

private enum Rule: String, Decodable {

    case endsWith = "ends_with"
    case equals

}

private extension BackendEnvironment2 {

    init(
        url: URL,
        payload: Payload
    ) throws {
        let endpoints = BackendEnvironment2.Endpoints(
            restAPIURL: payload.endpoints.backendURL,
            websocketURL: payload.endpoints.backendWSURL,
            blacklistURL: payload.endpoints.blackListURL,
            teamsURL: payload.endpoints.teamsURL,
            accountsURL: payload.endpoints.accountsURL,
            websiteURL: payload.endpoints.websiteURL,
            countlyURL: payload.endpoints.countlyURL
        )

        var pinnedKeys = [PinnedKey]()
        if let payload = payload.pinnedKeys {
            pinnedKeys = try payload.map {
                try PinnedKey($0)
            }
        }

        let proxyConfig = payload.apiProxy.map {
            BackendEnvironment2.ProxyConfig(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        let config = BackendEnvironment2.Config(
            endpoints: endpoints,
            pinnedKeys: pinnedKeys,
            proxyConfig: proxyConfig
        )

        self.init(
            title: payload.title,
            environmentType: .custom(url: url),
            config: config
        )
    }

}

private extension PinnedKey {

    init(_ trustData: TrustData) throws {
        try self.init(
            rawKey: trustData.certificateKey,
            hosts: trustData.hosts.map { host in
                switch host.rule {
                case .equals:
                    .equals(host.value)
                case .endsWith:
                    .endsWith(host.value)
                }
            }
        )
    }

}
