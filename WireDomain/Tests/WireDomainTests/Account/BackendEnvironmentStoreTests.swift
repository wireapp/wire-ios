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
// swiftlint:disable line_length

import Foundation
import Testing
@testable import WireDomain
@testable import WireNetwork

@Suite(.serialized)
final class BackendEnvironmentStoreTests {

    let url: URL

    init() {
        self.url = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        .first!
        .appendingPathComponent("BackendEnvironmentStoreTests")
    }

    deinit {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test("Store and fetch backend environment", arguments: [
        makeBackendEnvironment(proxyIncluded: true, proxyAuthenticated: true, withPinnedKey: true),
        makeBackendEnvironment(proxyIncluded: true, proxyAuthenticated: true, withPinnedKey: false),
        makeBackendEnvironment(proxyIncluded: true, proxyAuthenticated: false, withPinnedKey: false),
        makeBackendEnvironment(proxyIncluded: true, proxyAuthenticated: false, withPinnedKey: true)
    ])
    func storeAndFetchBackendEnvironment(
        _ environment: BackendEnvironment2
    ) throws {
        // Given
        let sut = try BackendEnvironmentStore(directory: url)
        let accountID = UUID()

        // When
        try sut.storeBackendEnvironment(
            environment,
            for: accountID
        )

        let storedEnvironment = try #require(
            try sut.fetchBackendEnvironment(accountID: accountID)
        )

        // Then
        #expect(environment == storedEnvironment)
    }

    @Test("Fetch non-existent backend environment")
    func fetchNonExistentBackendEnvironment() throws {
        // Given
        let sut = try BackendEnvironmentStore(directory: url)
        let accountId = UUID()

        // When
        let storedEnvironment = try sut.fetchBackendEnvironment(accountID: accountId)

        // Then
        #expect(storedEnvironment == nil)
    }

    @Test("Store and fetch backend metadata", arguments: [
        ResolvedBackendMetadata(
            apiVersion: .v9,
            domain: "foo.com",
            isFederationEnabled: false
        ),
        ResolvedBackendMetadata(
            apiVersion: .v8,
            domain: "bar.com",
            isFederationEnabled: true
        )
    ])
    func testStoreAndFetchBackendMetadata(_ metadata: ResolvedBackendMetadata) throws {
        // Given
        let sut = try BackendEnvironmentStore(directory: url)
        let accountID = UUID()

        // When
        try sut.storeBackendMetadata(
            metadata,
            for: accountID
        )

        let storedMetadata = try #require(
            try sut.fetchBackendMetadata(accountID: accountID)
        )

        // Then
        #expect(metadata == storedMetadata)
    }

    @Test("Fetch non-existent backend metadata")
    func fetchNonExistentBackendMetadata() throws {
        // Given
        let sut = try BackendEnvironmentStore(directory: url)
        let accountId = UUID()

        // When
        let storedMetadata = try sut.fetchBackendMetadata(accountID: accountId)

        // Then
        #expect(storedMetadata == nil)
    }

    @Test("Delete backend data")
    func deleteBackendData() throws {
        // Given
        let sut = try BackendEnvironmentStore(directory: url)
        let accountID = UUID()
        let environment = Self.makeBackendEnvironment()
        let metadata = ResolvedBackendMetadata(
            apiVersion: .v9,
            domain: "foo.com",
            isFederationEnabled: true
        )

        try sut.storeBackendEnvironment(environment, for: accountID)
        try sut.storeBackendMetadata(metadata, for: accountID)

        // When
        try sut.deleteBackendData(accountID: accountID)

        // Then
        let storedEnvironment = try sut.fetchBackendEnvironment(accountID: accountID)
        let storedMetadata = try sut.fetchBackendMetadata(accountID: accountID)

        #expect(storedEnvironment == nil)
        #expect(storedMetadata == nil)
    }

    private static func makeBackendEnvironment(
        proxyIncluded: Bool = true,
        proxyAuthenticated: Bool = true,
        withPinnedKey: Bool = true
    ) -> BackendEnvironment2 {
        let key =
            """
            MIIE/jCCA+agAwIBAgIQBmeNK7xaqmvwoGsKbGiEuzANBgkqhkiG9w0BAQsFADBNMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5EaWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTcxMjEyMDAwMDAwWhcNMTkwMjAxMTIwMDAwWjBKMQswCQYDVQQGEwJDSDEMMAoGA1UEBxMDWnVnMRgwFgYDVQQKEw9XaXJlIFN3aXNzIEdtYkgxEzARBgNVBAMMCioud2lyZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCt5jMFa6+dUph+A01fd1WNSeohW2XhepCcJxjqb+xYzXlNMrRuj0UqczE0A+0PMHpWJG+lmwoR59fymLXklyzi5mK5nzUhJXVurG2myMnnpiN6Z730NxrlyTfmlOFi4rqNny8bqkmJj2ZFj2cZp2J3ipYvu7AB6gifHaY4zsd6kIKHY05d34SNDiwGx+Bv6RatxVCYHO8sc9QOjKSb+b4G8vZ4nWeM82Iz8ah5duYhbVYzeJ+5xgmgP2D5Xk18d8A2tW7bDhhwsNp3QLzk1vxTWyAU2SuA6rOF3/XEeiTW47KOh4tMgcdiSvK9sESZ2Xq/5/YnUQzT4WP2+x4jZNitAgMBAAGjggHbMIIB1zAfBgNVHSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQU/0iA8JzB4tDtwNB/3NyYfCtfTZwwHwYDVR0RBBgwFoIKKi53aXJlLmNvbYIId2lyZS5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBrBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc3NjYS1zaGEyLWc2LmNybDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NzY2Etc2hhMi1nNi5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBAgIwfAYIKwYBBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAc6v6cf/EQmmeGU2nC87F6QgEIAIL3svgabImao3f01QFVxC0XX2Cf9+wofijspqq5Uj80nb04o5HNnZWX1agJmqp8jTYH2hw4+uiwFCld0QEptHMrCwEAyyouf0/cl2dfRv2V8m29W6Qb4+7pc1rEbFLl3fywmjgzpGkr1+cKE7pwkpgKqhulKkE4CDXant0Slj7cvDisSPy/kInJ5uHI29Z/SBCpACyHah6lkdIQyTo4uem1XH6i5UP9sTvCAZl0acHcPsvcJ50LeJvJC7sPNXr60xZYLIK5LIVrSSRhxtOB1WPMbzIQc5bF2LcSjXJNvXA5+RCO79om91mlheqPQ==
            """

        guard
            let keyData = Data(base64Encoded: key),
            let pinnedKey = try? PinnedKey(
                rawKey: keyData,
                hosts: [
                    .endsWith("prod-nginz-https.wire.com"),
                    .equals("clientblacklist.wire.com")
                ]
            )
        else {
            fatalError()
        }

        var proxyConfig: BackendEnvironment2.ProxyConfig?
        if proxyIncluded {
            proxyConfig = .init(
                host: "Host.com",
                port: 9999,
                needsAuthentication: proxyAuthenticated
            )
        }

        return BackendEnvironment2(
            title: "Staging",
            environmentType: .staging,
            config: .init(
                endpoints: .init(
                    restAPIURL: URL(string: "example.com")!,
                    websocketURL: URL(string: "example.com")!,
                    blacklistURL: URL(string: "example.com")!,
                    teamsURL: URL(string: "example.com")!,
                    accountsURL: URL(string: "example.com")!,
                    websiteURL: URL(string: "example.com")!,
                    countlyURL: nil
                ),
                pinnedKeys: withPinnedKey ? [pinnedKey] : [],
                proxyConfig: proxyConfig
            )
        )
    }
}

// swiftlint:enable line_length
