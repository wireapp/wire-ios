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

import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class PushSupportedProtocolsUseCaseTests: XCTestCase {

    private var sut: PushSupportedProtocolsUseCase!

    private var coreDataStackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()

        sut = PushSupportedProtocolsUseCase(
            featureConfigRepository: FeatureConfigRepository(
                featureConfigsAPI: MockFeatureConfigsAPI(),
                context: context
            ),
            userRepository: UserRepository(
                context: context,
                usersAPI: MockUsersAPI(),
                selfUserAPI: MockSelfUserAPI()
            )
        )
    }

    override func tearDown() async throws {
        sut = nil
        stack = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil

        try await super.tearDown()
    }

    // MARK: - Tests

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteus() async throws {
        // Given

        try await mock(allActiveMLSClients: true)
        await mock(remoteSupportedProtocols: [.proteus])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.proteus])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotStarted = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotStarted, [.proteus])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus])

        await mock(migrationState: .finalised)
        let supportedProtocols_Finalised = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Finalised, [.proteus])
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given

        try await mock(allActiveMLSClients: true)
        await mock(remoteSupportedProtocols: [.proteus, .mls])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.proteus, .mls])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotSupported = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotSupported, [.proteus, .mls])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus, .mls])

        await mock(migrationState: .finalised)
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteMLS() async throws {
        // Given

        try await mock(allActiveMLSClients: true)
        await mock(remoteSupportedProtocols: [.mls])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.mls])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotStarted = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotStarted, [.proteus, .mls])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus, .mls])

        await mock(migrationState: .finalised)
        let supportedProtocols_Finalised = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Finalised, [.mls])
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteus() async throws {
        // Given

        try await mock(allActiveMLSClients: false)
        await mock(remoteSupportedProtocols: [.proteus])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.proteus])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotStarted = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotStarted, [.proteus])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus])

        await mock(migrationState: .finalised)
        let supportedProtocols_Finalised = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Finalised, [.proteus])
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given

        try await mock(allActiveMLSClients: false)
        await mock(remoteSupportedProtocols: [.proteus, .mls])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.proteus])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotStarted = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotStarted, [.proteus])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus])

        await mock(migrationState: .finalised)
        let supportedProtocols_Finalised = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Finalised, [.proteus, .mls])
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteMLS() async throws {
        // Given

        try await mock(allActiveMLSClients: false)
        await mock(remoteSupportedProtocols: [.mls])

        // When / then

        await mock(migrationState: .disabled)
        let supportedProtocols_Disabled = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Disabled, [.mls])

        await mock(migrationState: .notStarted)
        let supportedProtocols_NotStarted = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_NotStarted, [.proteus])

        await mock(migrationState: .ongoing)
        let supportedProtocols_OnGoing = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_OnGoing, [.proteus])

        await mock(migrationState: .finalised)
        let supportedProtocols_Finalised = await sut.calculateSupportedProtocols()
        XCTAssertEqual(supportedProtocols_Finalised, [.mls])
    }

    // MARK: - Mock

    private func mock(allActiveMLSClients: Bool) async throws {
        await context.perform { [self] in
            let selfUser = createSelfUser(in: context)

            let selfClient = createSelfClient(in: context)
            selfClient.lastActiveDate = Date(timeIntervalSinceNow: -.oneDay)
            selfClient.mlsPublicKeys = randomMLSPublicKeys()

            let otherClient = createClient(for: selfUser, in: context)
            let validLastActiveDate = Date(timeIntervalSinceNow: -.oneHour)
            let invalidLastActiveDate = Date(timeIntervalSinceNow: -.fourWeeks - .oneHour)
            let validMLSPublicKeys = randomMLSPublicKeys()
            let invalidMLSPublicKeys = UserClient.MLSPublicKeys(ed25519: nil)

            if allActiveMLSClients {
                otherClient.lastActiveDate = validLastActiveDate
                otherClient.mlsPublicKeys = validMLSPublicKeys
            } else {
                /// Randomize the fields that make a client not an active mls client.
                otherClient.lastActiveDate = Bool.random() ? validLastActiveDate : invalidLastActiveDate
                otherClient.mlsPublicKeys = Bool.random() ? validMLSPublicKeys : invalidMLSPublicKeys

                /// But make sure we do have an invalid client.
                if otherClient.lastActiveDate == validLastActiveDate, otherClient.mlsPublicKeys == validMLSPublicKeys {
                    otherClient.lastActiveDate = invalidLastActiveDate
                }
            }
        }
    }

    private func randomMLSPublicKeys() -> WireDataModel.UserClient.MLSPublicKeys {
        UserClient.MLSPublicKeys(ed25519: Data.random().base64EncodedString())
    }

    private func mock(remoteSupportedProtocols: Set<Feature.MLS.Config.MessageProtocol>) async {
        await context.perform { [context] in
            Feature.updateOrCreate(
                havingName: .mls,
                in: context
            ) {
                $0.status = .enabled
                $0.config = try! JSONEncoder().encode(
                    Feature.MLS.Config(supportedProtocols: remoteSupportedProtocols)
                )
            }
        }
    }

    private func mock(migrationState: Scaffolding.MigrationState) async {
        switch migrationState {
        case .disabled:
            await context.perform { [context] in
                Feature.updateOrCreate(havingName: .mlsMigration, in: context) {
                    $0.status = .disabled
                    $0.config = try! JSONEncoder().encode(
                        Feature.MLSMigration.Config()
                    )
                }
            }

        case .notStarted:
            await context.perform { [context] in
                Feature.updateOrCreate(havingName: .mlsMigration, in: context) {
                    $0.status = .enabled
                    $0.config = try! JSONEncoder().encode(
                        Feature.MLSMigration.Config(
                            startTime: Date(timeIntervalSinceNow: .oneDay),
                            finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                        )
                    )
                }
            }

        case .ongoing:
            await context.perform { [context] in
                Feature.updateOrCreate(havingName: .mlsMigration, in: context) {
                    $0.status = .enabled
                    $0.config = try! JSONEncoder().encode(
                        Feature.MLSMigration.Config(
                            startTime: Date(timeIntervalSinceNow: -.oneDay),
                            finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                        )
                    )
                }
            }

        case .finalised:
            await context.perform { [context] in
                Feature.updateOrCreate(havingName: .mlsMigration, in: context) {
                    $0.status = .enabled
                    $0.config = try! JSONEncoder().encode(
                        Feature.MLSMigration.Config(
                            startTime: Date(timeIntervalSinceNow: -.fourWeeks),
                            finaliseRegardlessAfter: Date(timeIntervalSinceNow: -.oneDay)
                        )
                    )
                }
            }
        }
    }

    private func createSelfUser(in context: NSManagedObjectContext) -> ZMUser {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = UUID()

        return selfUser
    }

    private func createClient(for user: ZMUser, in context: NSManagedObjectContext) -> WireDataModel.UserClient {
        let client = UserClient.insertNewObject(in: context)
        client.user = user
        client.remoteIdentifier = UUID().uuidString

        return client
    }

    private func createSelfClient(in context: NSManagedObjectContext) -> WireDataModel.UserClient {
        let selfUser = createSelfUser(in: context)
        let client = createClient(for: selfUser, in: context)

        context.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)

        return client
    }
}

// MARK: - Scaffolding

private enum Scaffolding {
    enum MigrationState {
        case disabled
        case notStarted
        case ongoing
        case finalised
    }
}
