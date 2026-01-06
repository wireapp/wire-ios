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

import XCTest

@testable import WireDataModelSupport

class MLSClientManagerTests: ZMBaseManagedObjectTest {

    // MARK: - Properties

    private var sut: MLSClientManager!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockMLService: MockMLSServiceInterface!
    private var mockLegacyFeatureRepository: MockLegacyFeatureRepositoryInterface!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        mockLegacyFeatureRepository = MockLegacyFeatureRepositoryInterface()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockMLService = MockMLSServiceInterface()
        sut = MLSClientManager(
            coreCryptoProvider: mockCoreCryptoProvider,
            mlsService: mockMLService
        )
    }

    override func tearDown() {
        mockLegacyFeatureRepository = nil
        mockCoreCryptoProvider = nil
        mockMLService = nil
        sut = nil

        super.tearDown()
    }

    func test_InitializeMLSClient_Success() async throws {
        // Mock
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )
        mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }
        mockMLService.performPendingJoins_MockMethod = {}
        mockMLService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        // Given
        let mlsFeature = mockLegacyFeatureRepository.fetchMLS()
        let domain = "example.domain.com"

        let selfUser = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = domain
            return selfUser
        }

        let selfClient = await syncMOC.perform {
            self.createSelfClient(onMOC: self.syncMOC)
        }

        let hasRegisteredMLSClient = await syncMOC.perform {
            selfClient.hasRegisteredMLSClient
        }

        let remoteIdentifier = try XCTUnwrap(syncMOC.performAndWait { selfClient.remoteIdentifier })
        let qualifiedID = await syncMOC.perform {
            QualifiedClientID(
                userID: selfUser.remoteIdentifier,
                domain: domain,
                clientID: remoteIdentifier
            )
        }

        // When
        XCTAssertFalse(hasRegisteredMLSClient)
        await sut.initializeMLSClientIfNeeded(
            for: qualifiedID,
            hasRegisteredMLSClient: hasRegisteredMLSClient,
            mlsFeature: mlsFeature,
            isBackendMLSEnabled: true
        )

        // Then
        XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 1)
    }

    func test_InitializeMLSClient_Failed_MLSFeatureIsDisabled() async throws {
        // Mock
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .disabled,
            config: .init()
        )
        mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }
        mockMLService.performPendingJoins_MockMethod = {}
        mockMLService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        // Given
        let mlsFeature = mockLegacyFeatureRepository.fetchMLS()
        let domain = "example.domain.com"

        let selfUser = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = domain
            return selfUser
        }

        let selfClient = await syncMOC.perform {
            self.createSelfClient(onMOC: self.syncMOC)
        }

        let hasRegisteredMLSClient = await syncMOC.perform {
            selfClient.hasRegisteredMLSClient
        }

        let remoteIdentifier = try XCTUnwrap(syncMOC.performAndWait { selfClient.remoteIdentifier })
        let qualifiedID = await syncMOC.perform {
            QualifiedClientID(
                userID: selfUser.remoteIdentifier,
                domain: domain,
                clientID: remoteIdentifier
            )
        }

        // When
        XCTAssertFalse(hasRegisteredMLSClient)
        await sut.initializeMLSClientIfNeeded(
            for: qualifiedID,
            hasRegisteredMLSClient: hasRegisteredMLSClient,
            mlsFeature: mlsFeature,
            isBackendMLSEnabled: true
        )

        // Then
        XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 0)
    }

    func test_InitializeMLSClient_Failed_MLSClientAlreadyExists() async throws {
        // Mock
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )
        mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }
        mockMLService.performPendingJoins_MockMethod = {}
        mockMLService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        // Given
        let mlsFeature = mockLegacyFeatureRepository.fetchMLS()
        let domain = "example.domain.com"

        let selfUser = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = domain
            return selfUser
        }

        let selfClient = await syncMOC.perform {
            self.createSelfClient(onMOC: self.syncMOC)
        }

        let remoteIdentifier = try XCTUnwrap(syncMOC.performAndWait { selfClient.remoteIdentifier })
        let qualifiedID = await syncMOC.perform {
            QualifiedClientID(
                userID: selfUser.remoteIdentifier,
                domain: domain,
                clientID: remoteIdentifier
            )
        }

        // When
        let hasRegisteredMLSClient = await syncMOC.perform {
            selfClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "somekey")
            selfClient.needsToUploadMLSPublicKeys = false
            return selfClient.hasRegisteredMLSClient
        }
        XCTAssertTrue(hasRegisteredMLSClient)

        await sut.initializeMLSClientIfNeeded(
            for: qualifiedID,
            hasRegisteredMLSClient: hasRegisteredMLSClient,
            mlsFeature: mlsFeature,
            isBackendMLSEnabled: true
        )

        // Then
        XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 0)
    }

    func test_InitializeMLSClient_Failed_MLSIsDisabledOnBackend() async throws {
        // Mock
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )
        mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }
        mockMLService.performPendingJoins_MockMethod = {}
        mockMLService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        // Given
        let mlsFeature = mockLegacyFeatureRepository.fetchMLS()
        let domain = "example.domain.com"

        let selfUser = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = domain
            return selfUser
        }

        let selfClient = await syncMOC.perform {
            self.createSelfClient(onMOC: self.syncMOC)
        }

        let hasRegisteredMLSClient = await syncMOC.perform {
            selfClient.hasRegisteredMLSClient
        }

        let remoteIdentifier = try XCTUnwrap(syncMOC.performAndWait { selfClient.remoteIdentifier })
        let qualifiedID = await syncMOC.perform {
            QualifiedClientID(
                userID: selfUser.remoteIdentifier,
                domain: domain,
                clientID: remoteIdentifier
            )
        }

        // When
        XCTAssertFalse(hasRegisteredMLSClient)
        await sut.initializeMLSClientIfNeeded(
            for: qualifiedID,
            hasRegisteredMLSClient: hasRegisteredMLSClient,
            mlsFeature: mlsFeature,
            isBackendMLSEnabled: false
        )

        // Then
        XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 0)
    }

}
