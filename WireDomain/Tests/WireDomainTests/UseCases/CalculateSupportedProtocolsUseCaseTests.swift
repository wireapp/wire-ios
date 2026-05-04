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

import WireDataModel
import WireDataModelSupport
import WireNetwork
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class CalculateSupportedProtocolsUseCaseTests: XCTestCase {

    private var sut: CalculateSupportedProtocolsUseCase!
    private var userClientsLocalStore: MockUserClientsLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!

    private var coreDataStackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var modelHelper: ModelHelper!

    private var selfUser: ZMUser!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()

        userClientsLocalStore = MockUserClientsLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = CalculateSupportedProtocolsUseCase(
            featureConfigRepository: FeatureConfigRepository(
                featureConfigsAPI: MockFeatureConfigsAPI(),
                featureConfigLocalStore: FeatureConfigLocalStore(context: context)
            ),
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )

        selfUser = await context.perform { [context] in
            self.modelHelper.createSelfUser(in: context)
        }
        userLocalStore.fetchSelfUser_MockValue = selfUser
        userLocalStore.fetchSelfUserSupportedProtocols_MockValue = Set()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        selfUser = nil
        sut = nil
        stack = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil

        userClientsLocalStore = nil
    }

    // MARK: - Tests

    func test_CalculateSupportedProtocols_PreviousSupportedProtocolMLS_DoesNotRemoveMLS() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.proteus, .mls])

        userLocalStore.fetchSelfUserSupportedProtocols_MockValue = [.proteus, .mls]
        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false

        let supportedProtocols = await sut.invoke()

        // Then
        XCTAssertEqual([WireNetwork.MessageProtocol.mls, WireNetwork.MessageProtocol.proteus], supportedProtocols)
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteus() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.proteus])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.proteus]),
                (migrationState: .notStarted, supportedProtocols: [.proteus]),
                (migrationState: .ongoing, supportedProtocols: [.proteus]),
                (migrationState: .finalised, supportedProtocols: [.proteus])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.proteus, .mls])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.proteus, .mls]),
                (migrationState: .notStarted, supportedProtocols: [.proteus, .mls]),
                (migrationState: .ongoing, supportedProtocols: [.proteus, .mls]),
                (migrationState: .finalised, supportedProtocols: [.proteus, .mls])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteMLS() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.mls])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.mls]),
                (migrationState: .notStarted, supportedProtocols: [.proteus, .mls]),
                (migrationState: .ongoing, supportedProtocols: [.proteus, .mls]),
                (migrationState: .finalised, supportedProtocols: [.mls])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteus() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.proteus])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.proteus]),
                (migrationState: .notStarted, supportedProtocols: [.proteus]),
                (migrationState: .ongoing, supportedProtocols: [.proteus]),
                (migrationState: .finalised, supportedProtocols: [.proteus])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.proteus, .mls])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.proteus]),
                (migrationState: .notStarted, supportedProtocols: [.proteus]),
                (migrationState: .ongoing, supportedProtocols: [.proteus]),
                (migrationState: .finalised, supportedProtocols: [.proteus, .mls])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_IfSelfClientSupportMLS_NoOverride() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.mls])

        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false
        let selfProtocols = [WireDataModel.MessageProtocol.proteus, WireDataModel.MessageProtocol.mls]
        userLocalStore.fetchSelfUserSupportedProtocols_MockValue = Set(selfProtocols)
        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .notStarted, supportedProtocols: [.proteus, .mls])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteMLS() async throws {
        // Given
        await setup(remoteSupportedProtocols: [.mls])
        userClientsLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false

        let testCases: [
            (migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireNetwork.MessageProtocol>)
        ] =
            [
                (migrationState: .disabled, supportedProtocols: [.mls]),
                (migrationState: .notStarted, supportedProtocols: [.proteus]),
                (migrationState: .ongoing, supportedProtocols: [.proteus]),
                (migrationState: .finalised, supportedProtocols: [.mls])
            ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            let supportedProtocols = await sut.invoke()
            // Then
            XCTAssertEqual(testCase.supportedProtocols, supportedProtocols)
        }
    }

    // MARK: - Setup

    private func randomMLSPublicKeys() -> WireDataModel.UserClient.MLSPublicKeys {
        UserClient.MLSPublicKeys(ed25519: Data.random().base64EncodedString())
    }

    private func setup(remoteSupportedProtocols: Set<Feature.MLS.Config.MessageProtocol>) async {
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

    private func setup(migrationState: Scaffolding.MigrationState) async {
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

    private enum Scaffolding {
        enum MigrationState {
            case disabled
            case notStarted
            case ongoing
            case finalised
        }
    }
}
