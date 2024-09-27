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

import WireCoreCrypto
import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy

// MARK: - GetE2eIdentityCertificatesUseCaseTests

final class GetE2eIdentityCertificatesUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        coreCrypto = MockCoreCryptoProtocol()
        safeCoreCrypto = MockSafeCoreCrypto(coreCrypto: coreCrypto)
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        coreCryptoProvider.coreCrypto_MockValue = safeCoreCrypto
        sut = GetE2eIdentityCertificatesUseCase(
            coreCryptoProvider: coreCryptoProvider,
            syncContext: stack.syncContext
        )
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        coreCrypto = nil
        safeCoreCrypto = nil
        coreCryptoProvider = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func mockIdentity(
        clientID: String,
        handle: String,
        name: String,
        status: DeviceStatus
    ) -> WireCoreCrypto.WireIdentity {
        .init(
            clientId: clientID,
            status: status,
            thumbprint: "QrsvPI0PDiJyAgsF-p3HoSyWLGWjyKwMdqlL0zWZOew",
            credentialType: .x509,
            x509Identity: X509Identity(
                handle: "wireapp://%40\(handle)",
                displayName: name,
                domain: "local.com",
                certificate: mockCertificate,
                serialNumber: "00eac2d1d30f517a891231648a4322dfb2",
                notBefore: 1_709_112_038,
                notAfter: 1_716_888_038
            )
        )
    }

    func test_CertificateNameAndHandleIsValidated() async throws {
        // Given
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        let clientID1 = MLSClientID.random()
        let clientID2 = MLSClientID.random()
        let clientID3 = MLSClientID.random()
        let clientID4 = MLSClientID.random()
        let groupID = MLSGroupID.random()

        // Self user with 4 clients
        try await stack.syncContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.syncContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            modelHelper.createSelfClient(id: clientID1.clientID, in: self.stack.syncContext)
            modelHelper.createClient(id: clientID2.clientID, for: selfUser)
            modelHelper.createClient(id: clientID3.clientID, for: selfUser)
            modelHelper.createClient(id: clientID4.clientID, for: selfUser)

            try self.stack.syncContext.save()
        }

        // Mock
        let validIdentity = mockIdentity(
            clientID: clientID1.rawValue,
            handle: "\(selfUserHandle)@\(domain)",
            name: "Ms Foo",
            status: .valid
        )

        let identityWithInvalidHandle = mockIdentity(
            clientID: clientID2.rawValue,
            handle: "bar@\(domain)",
            name: "Ms Foo",
            status: .valid
        )

        let identityWithInvalidName = mockIdentity(
            clientID: clientID3.rawValue,
            handle: "\(selfUserHandle)@\(domain)",
            name: "Ms Bar",
            status: .valid
        )

        let identityWithInvalidStatus = mockIdentity(
            clientID: clientID4.rawValue,
            handle: "bar@\(domain)",
            name: "Ms Bar",
            status: .revoked
        )

        coreCrypto.getDeviceIdentitiesConversationIdDeviceIds_MockMethod = { _, _ in
            [
                validIdentity,
                identityWithInvalidHandle,
                identityWithInvalidName,
                identityWithInvalidStatus,
            ]
        }

        // When
        let certificates = try await sut.invoke(
            mlsGroupId: groupID,
            clientIds: [clientID1, clientID2, clientID3, clientID4]
        )

        // Then
        XCTAssertEqual(certificates.count, 4)

        let certificate1 = try XCTUnwrap(certificates.first(where: {
            $0.clientId == clientID1.rawValue
        }))

        // Name and handle matched, so it's valid.
        XCTAssertEqual(certificate1.status, .valid)

        let certificate2 = try XCTUnwrap(certificates.first(where: {
            $0.clientId == clientID2.rawValue
        }))

        // Handle didn't match, invalid.
        XCTAssertEqual(certificate2.status, .invalid)

        let certificate3 = try XCTUnwrap(certificates.first(where: {
            $0.clientId == clientID3.rawValue
        }))

        // Name didn't match, invalid.
        XCTAssertEqual(certificate3.status, .invalid)

        let certificate4 = try XCTUnwrap(certificates.first(where: {
            $0.clientId == clientID4.rawValue
        }))

        // Status is revoked, further validation inrelevant.
        XCTAssertEqual(certificate4.status, .revoked)
    }

    // MARK: Private

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()

    private var sut: GetE2eIdentityCertificatesUseCase!
    private var coreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var safeCoreCrypto: MockSafeCoreCrypto!
    private var coreCrypto: MockCoreCryptoProtocol!
}

private let mockCertificate =
    """
    -----BEGIN CERTIFICATE-----
    MIICaTCCAg+gAwIBAgIQSe+7TFUrGk5CjvIhcHC4vTAKBggqhkjOPQQDAjAuMSww
    KgYDVQQDEyNlbG5hLndpcmUubGluayBFMkVJIEludGVybWVkaWF0ZSBDQTAeFw0y
    NDAyMjIxNjM4NTdaFw0yNDA1MjIxNjM4NTdaMC4xFzAVBgNVBAoTDmVsbmEud2ly
    ZS5saW5rMRMwEQYDVQQDEwpLYXRlcmluYSBOMCowBQYDK2VwAyEAVCFEGPXHqVTY
    qNDTQXo9pTzjdWbYOdSihroOAvJQG7+jggE8MIIBODAOBgNVHQ8BAf8EBAMCB4Aw
    EwYDVR0lBAwwCgYIKwYBBQUHAwIwHQYDVR0OBBYEFLhVOdMwMi/B2X6A9M/5MHxt
    2FeiMB8GA1UdIwQYMBaAFOW0E419T7NPbLk2HuLc11CoJTfWMHgGA1UdEQRxMG+G
    KXdpcmVhcHA6Ly8lNDBrYXRlcmluYV93aXJlQGVsbmEud2lyZS5saW5rhkJ3aXJl
    YXBwOi8vMmVxZWVocGRSdEN0NEJHdGtGU1lTUSUyMTY2YTE4MThmM2QwNjMwMTBA
    ZWxuYS53aXJlLmxpbmswLwYDVR0fBCgwJjAkoCKgIIYeaHR0cDovL2FjbWUuZWxu
    YS53aXJlLmxpbmsvY3JsMCYGDCsGAQQBgqRkxihAAQQWMBQCAQYEDWtleWNsb2Fr
    dGVhbXMEADAKBggqhkjOPQQDAgNIADBFAiAWttChBvdaCyx7OLDVI+R+oSg6fhS3
    jtHioLFXcH4cFAIhAP8qNs0gS/KSPYEfUR17YcSBl6w/o2PC0B370B7MzGAR
    -----END CERTIFICATE-----
    """
