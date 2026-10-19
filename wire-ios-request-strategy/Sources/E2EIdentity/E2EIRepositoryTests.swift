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

import Testing
import WireCoreCrypto

@testable import WireDataModelSupport
@testable import WireRequestStrategy
@testable import WireRequestStrategySupport

/// These tests run against a real `PkiEnvironment` backed by an in-memory database, so they verify
/// how CoreCrypto actually behaves when the same trust anchor is registered more than once.
@Suite("E2EIRepository")
struct E2EIRepositoryTests {

    // MARK: - Fixture

    private let acmeApi = MockAcmeAPIInterface()
    private let coreCryptoProvider = MockCoreCryptoProviderProtocol()

    private func makeSUT(pkiEnvironment: PkiEnvironment) -> E2EIRepository {
        coreCryptoProvider.pkiEnvironment_MockValue = .some(pkiEnvironment)
        return E2EIRepository(acmeApi: acmeApi, coreCryptoProvider: coreCryptoProvider)
    }

    private func makePKIEnvironment() async throws -> PkiEnvironment {
        try await PkiEnvironment(hooks: StubPKIEnvironmentHooks(), database: inMemoryDatabase())
    }

    // MARK: - Tests

    @Test("Registers the trust anchor on the first call")
    func registersTrustAnchor() async throws {
        // Given
        let pkiEnvironment = try await makePKIEnvironment()
        let sut = makeSUT(pkiEnvironment: pkiEnvironment)
        acmeApi.getTrustAnchor_MockMethod = { Self.rootCA1 }

        // When
        try await sut.fetchTrustAnchor()

        // Then
        #expect(try await pkiEnvironment.getTrustAnchors().count == 1)
    }

    @Test("Fetching the trust anchor again after it was already registered does not fail")
    func fetchingAlreadyRegisteredTrustAnchorDoesNotFail() async throws {
        // Given: a previous (e.g. cancelled) enrollment attempt already registered the trust anchor
        let pkiEnvironment = try await makePKIEnvironment()
        let sut = makeSUT(pkiEnvironment: pkiEnvironment)
        acmeApi.getTrustAnchor_MockMethod = { Self.rootCA1 }
        try await sut.fetchTrustAnchor()

        // When / Then
        try await sut.fetchTrustAnchor()
        #expect(try await pkiEnvironment.getTrustAnchors().count == 1)
    }

    @Test("Registers a different trust anchor alongside an existing one")
    func registersDifferentTrustAnchor() async throws {
        // Given
        let pkiEnvironment = try await makePKIEnvironment()
        let sut = makeSUT(pkiEnvironment: pkiEnvironment)
        acmeApi.getTrustAnchor_MockMethod = { Self.rootCA1 }
        try await sut.fetchTrustAnchor()

        // When
        acmeApi.getTrustAnchor_MockMethod = { Self.rootCA2 }
        try await sut.fetchTrustAnchor()

        // Then
        #expect(try await pkiEnvironment.getTrustAnchors().count == 2)
    }

    // MARK: - Fixtures

    private static let rootCA1 = """
-----BEGIN CERTIFICATE-----
MIIBgTCCATOgAwIBAgIUM6WGkyTyvuRiFGKEclmN4uHxskAwBQYDK2VwMC0xEjAQ
BgNVBAoMCVdpcmUgVGVzdDEXMBUGA1UEAwwOVGVzdCBSb290IENBIDEwIBcNMjYx
MDE5MTE0NDA1WhgPMjEyNjA5MjUxMTQ0MDVaMC0xEjAQBgNVBAoMCVdpcmUgVGVz
dDEXMBUGA1UEAwwOVGVzdCBSb290IENBIDEwKjAFBgMrZXADIQAYJABe4jpFisK6
VOEgtPwuZoB7W6Kde7P5lvi/BybVU6NjMGEwHQYDVR0OBBYEFHfPvG5Ut0mSTAT2
dLndQlIQ9JMaMB8GA1UdIwQYMBaAFHfPvG5Ut0mSTAT2dLndQlIQ9JMaMA8GA1Ud
EwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAUGAytlcANBALTcazerDSa0aG82
9NN1qRe+2YNGlSl7K6cEt5locw1c7eOvbPPkJgnIBzS6lz+KIrlhmhZ6DpH8GyFm
SeE+aQs=
-----END CERTIFICATE-----
"""

    private static let rootCA2 = """
-----BEGIN CERTIFICATE-----
MIIBgTCCATOgAwIBAgIUI6oi4BWhZagbtiaFUotGkHULY00wBQYDK2VwMC0xEjAQ
BgNVBAoMCVdpcmUgVGVzdDEXMBUGA1UEAwwOVGVzdCBSb290IENBIDIwIBcNMjYx
MDE5MTE0NDA1WhgPMjEyNjA5MjUxMTQ0MDVaMC0xEjAQBgNVBAoMCVdpcmUgVGVz
dDEXMBUGA1UEAwwOVGVzdCBSb290IENBIDIwKjAFBgMrZXADIQDGHY6VpY29gUcX
EBmaD7CB/Pi3G0O/E7UorA+sqcBs66NjMGEwHQYDVR0OBBYEFAg+7hKXkYjc9USN
8FXvRWJboOqcMB8GA1UdIwQYMBaAFAg+7hKXkYjc9USN8FXvRWJboOqcMA8GA1Ud
EwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAUGAytlcANBAMeQKKm3FVKEtc0J
gotK8jm96y82rB0cl86P3+3yY5bSmR12XZEG1m4/4hHqm9p9wW0FRlilkTpuQ4WH
5UAc3gU=
-----END CERTIFICATE-----
"""
}

// MARK: - Test doubles

/// The trust anchor and intermediate certificate paths never use the hooks.
private final class StubPKIEnvironmentHooks: PkiEnvironmentHooks {
    func httpRequest(
        method: HttpMethod,
        url: String,
        headers: [HttpHeader],
        body: Data
    ) async throws -> HttpResponse {
        fatalError("not expected to be called")
    }

    func authenticate(idp: String, keyAuth: String, acmeAud: String, acquisitionSnapshot: Data) async throws -> String {
        fatalError("not expected to be called")
    }

    func getBackendNonce() async throws -> String {
        fatalError("not expected to be called")
    }

    func fetchBackendAccessToken(dpop: String) async throws -> String {
        fatalError("not expected to be called")
    }
}
