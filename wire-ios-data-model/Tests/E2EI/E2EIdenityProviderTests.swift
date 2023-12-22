//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest
import X509
import SwiftASN1
import WireCoreCrypto

@testable import WireDataModel

final class E2EIdenityProviderTests: XCTestCase {

    let kGracePeriod: Double = 10

    func testGivenCertificateIsExpiredWhenShouldUpdateCertificateIsCalledThenReturnsTrue() {
        let provider = E2eIdentityProvider(
            clientIds: nil,
            userIds: nil,
            conversationId: "",
            gracePeriod: kGracePeriod
        )
        do {
            let pemDocument = try PEMDocument(pemString: MockPEMDocuments.expired)
            let certificate = try Certificate(pemDocument: pemDocument)
            let exipredCertificate = E2eIdentityCertificate(
                certificate: certificate,
                certificateDetails: "",
                certificateStatus: .expired,
                mlsThumbprint: ""
            )
            XCTAssertTrue(provider.shouldUpdateCertificate(for: exipredCertificate))
        } catch {
            XCTFail("Expired PEMDocument should be valid")
        }
    }

    func testGivenCertificateIsValidWhenShouldUpdateCertificateIsCalledThenReturnsFalse() {
        let provider = E2eIdentityProvider(
            clientIds: nil,
            userIds: nil,
            conversationId: "",
            gracePeriod: kGracePeriod
        )
        do {
            let pemDocument = try PEMDocument(pemString: MockPEMDocuments.valid)
            let certificate = try Certificate(pemDocument: pemDocument)
            let exipredCertificate = E2eIdentityCertificate(
                certificate: certificate,
                certificateDetails: "",
                certificateStatus: .valid,
                mlsThumbprint: ""
            )
            XCTAssertFalse(provider.shouldUpdateCertificate(for: exipredCertificate))
        } catch {
            XCTFail("Expired PEMDocument should be valid")
        }
    }

    func testGivenCryptoProviderReturnsFalseWhenIsE2EIdentityEnabledThenReturnsTrue() {
        let mockCryptoProvider = MockE2EITestCryptoProvider()
        mockCryptoProvider.setE2EIdentityEnabled = true
        let provider = E2eIdentityProvider(
            clientIds: nil,
            userIds: nil,
            conversationId: "",
            gracePeriod: kGracePeriod,
            cryptoProvider: mockCryptoProvider
        )
        XCTAssertTrue(provider.isE2EIdentityEnabled())
    }

    func testGivenCryptoProviderReturnsFalseWhenIsE2EIdentityEnabledThenReturnsFalse() {
        let mockCryptoProvider = MockE2EITestCryptoProvider()
        mockCryptoProvider.setE2EIdentityEnabled = false

        let provider = E2eIdentityProvider(
            clientIds: nil,
            userIds: nil,
            conversationId: "",
            gracePeriod: kGracePeriod,
            cryptoProvider: mockCryptoProvider
        )
        XCTAssertFalse(provider.isE2EIdentityEnabled())
    }

    func testGivenUserIdsWhenFetchCertificatesIsCalledThenReturnsCertificates() async throws {
        let testWireIdentity = WireIdentity(
            clientId: .random(length: 10),
            handle: .random(length: 4),
            displayName: .random(length: 5),
            domain: .random(length: 10)
        )
        let mockCryptoProvider = MockE2EITestCryptoProvider()
        mockCryptoProvider.setWireIdentitiesForUserIds = [testWireIdentity]

        let provider = E2eIdentityProvider(
            clientIds: nil,
            userIds: [""],
            conversationId: "",
            gracePeriod: kGracePeriod,
            cryptoProvider: mockCryptoProvider
        )
        let certificates = try await provider.fetchCertificates()
        XCTAssertEqual(testWireIdentity.certificate, certificates.first?.certificateDetails)
        XCTAssertEqual(testWireIdentity.thumbprint, certificates.first?.mlsThumbprint)
        XCTAssertEqual(testWireIdentity.status, certificates.first?.status)
    }

    func testGivenClientIdsWhenFetchCertificatesIsCalledThenReturnsCertificates() async throws {
        let testWireIdentity = WireIdentity(
            clientId: .random(length: 10),
            handle: .random(length: 4),
            displayName: .random(length: 5),
            domain: .random(length: 10)
        )
        let mockCryptoProvider = MockE2EITestCryptoProvider()
        mockCryptoProvider.setWireIdentitiesForClientIds = [testWireIdentity]

        let provider = E2eIdentityProvider(
            clientIds: [ClientId()],
            userIds: nil,
            conversationId: "",
            gracePeriod: kGracePeriod,
            cryptoProvider: mockCryptoProvider
        )
        let certificates = try await provider.fetchCertificates()
        XCTAssertEqual(testWireIdentity.certificate, certificates.first?.certificateDetails)
        XCTAssertEqual(testWireIdentity.thumbprint, certificates.first?.mlsThumbprint)
        XCTAssertEqual(testWireIdentity.status, certificates.first?.status)
    }
}
