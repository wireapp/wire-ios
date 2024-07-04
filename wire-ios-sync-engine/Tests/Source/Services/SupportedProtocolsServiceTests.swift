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

import WireDataModelSupport
import WireDomainSupport
@testable import WireSyncEngine
import WireSyncEngineSupport
import XCTest

final class SupportedProtocolsServiceTests: XCTestCase {

    private var coreDataStackHelper: CoreDataStackHelper!
    private var mockCoreDataStack: CoreDataStack!

    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var mockSelfUserProvider: MockSelfUserProviderProtocol!

    private var sut: SupportedProtocolsService!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataStackHelper.createStack()

        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockSelfUserProvider = MockSelfUserProviderProtocol()

        sut = SupportedProtocolsService(
            featureRepository: mockFeatureRepository,
            selfUserProvider: mockSelfUserProvider
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockFeatureRepository = nil
        mockSelfUserProvider = nil
        mockCoreDataStack = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil

        try await super.tearDown()
    }

    // MARK: - Mock

    private func mock(allActiveMLSClients: Bool) throws {
        let selfUser = createSelfUser(in: syncContext)
        mockSelfUserProvider.fetchSelfUser_MockValue = selfUser

        let selfClient = createSelfClient(in: syncContext)
        selfClient.lastActiveDate = Date(timeIntervalSinceNow: -.oneDay)
        selfClient.mlsPublicKeys = randomMLSPublicKeys()

        let otherClient = createClient(for: selfUser, in: syncContext)
        let validLastActiveDate = Date(timeIntervalSinceNow: -.oneHour)
        let invalidLastActiveDate = Date(timeIntervalSinceNow: -.fourWeeks - .oneHour)
        let validMLSPublicKeys = randomMLSPublicKeys()
        let invalidMLSPublicKeys = UserClient.MLSPublicKeys(ed25519: nil)

        if allActiveMLSClients {
            otherClient.lastActiveDate = validLastActiveDate
            otherClient.mlsPublicKeys = validMLSPublicKeys
        } else {
            // Randomize the fields that make a client not an active mls client.
            otherClient.lastActiveDate = Bool.random() ? validLastActiveDate : invalidLastActiveDate
            otherClient.mlsPublicKeys = Bool.random() ? validMLSPublicKeys : invalidMLSPublicKeys

            // But make sure we do have an invalid client.
            if otherClient.lastActiveDate == validLastActiveDate && otherClient.mlsPublicKeys == validMLSPublicKeys {
                otherClient.lastActiveDate = invalidLastActiveDate
            }
        }
    }

    private func randomMLSPublicKeys() -> UserClient.MLSPublicKeys {
        return UserClient.MLSPublicKeys(ed25519: Data.random().base64EncodedString())
    }

    private func mock(remoteSupportedProtocols: Set<Feature.MLS.Config.MessageProtocol>) {
        mockFeatureRepository.fetchMLS_MockValue = .init(
            status: .enabled,
            config: Feature.MLS.Config(supportedProtocols: remoteSupportedProtocols)
        )
    }

    private func mock(migrationState: MigrationState) {
        switch migrationState {
        case .disabled:
            mockFeatureRepository.fetchMLSMigration_MockValue = .init(
                status: .disabled,
                config: .init()
            )

        case .notStarted:
            mockFeatureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: .oneDay),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                )
            )

        case .ongoing:
            mockFeatureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: -.oneDay),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                )
            )

        case .finalised:
            mockFeatureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: -.fourWeeks),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: -.oneDay)
                )
            )
        }
    }

    private func createSelfUser(in context: NSManagedObjectContext) -> ZMUser {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = UUID()

        return selfUser
    }

    private func createClient(for user: ZMUser, in context: NSManagedObjectContext) -> UserClient {
        let client = UserClient.insertNewObject(in: context)
        client.user = user
        client.remoteIdentifier = UUID().uuidString

        return client
    }

    private func createSelfClient(in context: NSManagedObjectContext) -> UserClient {
        let selfUser = createSelfUser(in: context)
        let client = createClient(for: selfUser, in: context)

        context.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)

        return client
    }

    // MARK: - Tests

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteus() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.proteus])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteusAndMLS() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.proteus, .mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteMLS() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteus() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.proteus])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteusAndMLS() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.proteus, .mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteMLS() throws {
        try syncContext.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])
        }
    }
}

// MARK: - MigrationState

private enum MigrationState {

    case disabled
    case notStarted
    case ongoing
    case finalised

}
