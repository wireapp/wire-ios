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
import Testing
@testable import WireNetwork

struct BackendEnvironmentDecodingTests {

    private func loadTestData(fileName: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(
                forResource: fileName,
                withExtension: "json"
            )
        )
        return try Data(contentsOf: url)
    }

    @Test("Decoding a standard config")
    func decodingStandardConfig() async throws {
        // Given
        let data = try loadTestData(fileName: "backend-standard")

        // When
        let environment = try BackendEnvironment2.fromJSON(
            data,
            environmentType: .default
        )

        // Then
        #expect(environment.title == "Test Backend")
        #expect(environment.environmentType == .default)

        let endpoints = environment.config.endpoints
        #expect(endpoints.restAPIURL == URL(string: "https://api.example.com")!)
        #expect(endpoints.websocketURL == URL(string: "https://ws.example.com")!)
        #expect(endpoints.blacklistURL == URL(string: "https://blacklist.example.com")!)
        #expect(endpoints.teamsURL == URL(string: "https://teams.example.com")!)
        #expect(endpoints.accountsURL == URL(string: "https://accounts.example.com")!)
        #expect(endpoints.websiteURL == URL(string: "https://example.com")!)
        #expect(endpoints.countlyURL == URL(string: "https://analytics.example.com")!)

        #expect(environment.config.pinnedKeys.isEmpty)
        #expect(environment.config.proxyConfig == nil)
    }

    @Test("Decoding a config with certificate pinning")
    func decodingConfigWithPinnedKeys() async throws {
        // Given
        let data = try loadTestData(fileName: "backend-with-pinned-keys")

        // When
        let environment = try BackendEnvironment2.fromJSON(
            data,
            environmentType: .default
        )

        // Then
        #expect(environment.title == "Test Backend With Pinning")
        #expect(environment.environmentType == .default)

        let endpoints = environment.config.endpoints
        #expect(endpoints.restAPIURL == URL(string: "https://api.example.com")!)
        #expect(endpoints.websocketURL == URL(string: "https://ws.example.com")!)
        #expect(endpoints.blacklistURL == URL(string: "https://blacklist.example.com")!)
        #expect(endpoints.teamsURL == URL(string: "https://teams.example.com")!)
        #expect(endpoints.accountsURL == URL(string: "https://accounts.example.com")!)
        #expect(endpoints.websiteURL == URL(string: "https://example.com")!)
        #expect(endpoints.countlyURL == nil)

        try #require(environment.config.pinnedKeys.count == 1)
        let pinnedKey = environment.config.pinnedKeys[0]
        #expect(pinnedKey.hosts.count == 3)
        #expect(pinnedKey.hosts.contains(.endsWith("api.example.com")))
        #expect(pinnedKey.hosts.contains(.endsWith("ws.example.com")))
        #expect(pinnedKey.hosts.contains(.equals("blacklist.example.com")))

        #expect(environment.config.proxyConfig == nil)
    }

    @Test("Decoding a config with a proxy")
    func decodingConfigWithProxy() async throws {
        // Given
        let data = try loadTestData(fileName: "backend-with-proxy")

        // When
        let environment = try BackendEnvironment2.fromJSON(
            data,
            environmentType: .default
        )

        // Then
        #expect(environment.title == "Test Backend With Proxy")
        #expect(environment.environmentType == .default)

        let endpoints = environment.config.endpoints
        #expect(endpoints.restAPIURL == URL(string: "https://api-proxy.example.com")!)
        #expect(endpoints.websocketURL == URL(string: "https://ws-proxy.example.com")!)
        #expect(endpoints.blacklistURL == URL(string: "https://blacklist.example.com")!)
        #expect(endpoints.teamsURL == URL(string: "https://teams-proxy.example.com")!)
        #expect(endpoints.accountsURL == URL(string: "https://accounts-proxy.example.com")!)
        #expect(endpoints.websiteURL == URL(string: "https://proxy.example.com")!)
        #expect(endpoints.countlyURL == nil)

        #expect(environment.config.pinnedKeys.isEmpty)

        #expect(environment.config.proxyConfig != nil)
        let proxyConfig = try #require(environment.config.proxyConfig)
        #expect(proxyConfig.host == "proxy.example.com")
        #expect(proxyConfig.port == 8080)
        #expect(proxyConfig.needsAuthentication == true)
    }

    @Test("Decoding a config with both pinned keys and proxy")
    func decodingConfigWithPinnedKeysAndProxy() async throws {
        // Given
        let data = try loadTestData(fileName: "backend-with-pinned-keys-and-proxy")

        // When
        let environment = try BackendEnvironment2.fromJSON(
            data,
            environmentType: .default
        )

        // Then
        #expect(environment.title == "Test Backend With Pinning And Proxy")
        #expect(environment.environmentType == .default)

        let endpoints = environment.config.endpoints
        #expect(endpoints.restAPIURL == URL(string: "https://api-proxy.example.com")!)
        #expect(endpoints.websocketURL == URL(string: "https://ws-proxy.example.com")!)
        #expect(endpoints.blacklistURL == URL(string: "https://blacklist.example.com")!)
        #expect(endpoints.teamsURL == URL(string: "https://teams-proxy.example.com")!)
        #expect(endpoints.accountsURL == URL(string: "https://accounts-proxy.example.com")!)
        #expect(endpoints.websiteURL == URL(string: "https://proxy.example.com")!)
        #expect(endpoints.countlyURL == nil)

        try #require(environment.config.pinnedKeys.count == 1)
        let pinnedKey = environment.config.pinnedKeys[0]
        #expect(pinnedKey.hosts.count == 3)
        #expect(pinnedKey.hosts.contains(.endsWith("api-proxy.example.com")))
        #expect(pinnedKey.hosts.contains(.endsWith("ws-proxy.example.com")))
        #expect(pinnedKey.hosts.contains(.equals("proxy.example.com")))

        #expect(environment.config.proxyConfig != nil)
        let proxyConfig = try #require(environment.config.proxyConfig)
        #expect(proxyConfig.host == "proxy.example.com")
        #expect(proxyConfig.port == 8080)
        #expect(proxyConfig.needsAuthentication == true)
    }

}
