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
@testable import WireDomain
@testable import WireDomainSupport
import XCTest

final class PushSupportedProtocolsUseCaseTests: XCTestCase {

    private var sut: PushSupportedProtocolsUseCase!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var modelHelper: ModelHelper!
    private var mockSelfUserAPI: MockSelfUserAPI!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        mockSelfUserAPI = MockSelfUserAPI()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = PushSupportedProtocolsUseCase(
            featureConfigRepository: FeatureConfigRepository(
                featureConfigsAPI: MockFeatureConfigsAPI(),
                context: context
            ),
            userRepository: UserRepository(
                usersAPI: MockUsersAPI(),
                selfUserAPI: mockSelfUserAPI,
                conversationLabelsRepository: MockConversationLabelsRepositoryProtocol(), conversationRepository: MockConversationRepositoryProtocol(),
                userLocalStore: userLocalStore
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        userLocalStore = nil
        stack = nil
        modelHelper = nil
        mockSelfUserAPI = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteus() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: true)
        await setup(remoteSupportedProtocols: [.proteus])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.proteus]),
            (migrationState: .notStarted, supportedProtocols: [.proteus]),
            (migrationState: .ongoing, supportedProtocols: [.proteus]),
            (migrationState: .finalised, supportedProtocols: [.proteus])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: true)
        await setup(remoteSupportedProtocols: [.proteus, .mls])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.proteus, .mls]),
            (migrationState: .notStarted, supportedProtocols: [.proteus, .mls]),
            (migrationState: .ongoing, supportedProtocols: [.proteus, .mls]),
            (migrationState: .finalised, supportedProtocols: [.proteus, .mls])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteMLS() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: true)
        await setup(remoteSupportedProtocols: [.mls])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.mls]),
            (migrationState: .notStarted, supportedProtocols: [.proteus, .mls]),
            (migrationState: .ongoing, supportedProtocols: [.proteus, .mls]),
            (migrationState: .finalised, supportedProtocols: [.mls])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteus() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: false)
        await setup(remoteSupportedProtocols: [.proteus])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = true

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.proteus]),
            (migrationState: .notStarted, supportedProtocols: [.proteus]),
            (migrationState: .ongoing, supportedProtocols: [.proteus]),
            (migrationState: .finalised, supportedProtocols: [.proteus])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteusAndMLS() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: false)
        await setup(remoteSupportedProtocols: [.proteus, .mls])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.proteus]),
            (migrationState: .notStarted, supportedProtocols: [.proteus]),
            (migrationState: .ongoing, supportedProtocols: [.proteus]),
            (migrationState: .finalised, supportedProtocols: [.proteus, .mls])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteMLS() async throws {
        // Given

        let selfUser = try await setup(allActiveMLSClients: false)
        await setup(remoteSupportedProtocols: [.mls])

        mockSelfUserAPI.pushSupportedProtocols_MockMethod = { _ in }
        userLocalStore.fetchSelfUser_MockMethod = { selfUser }
        userLocalStore.allSelfUserClientsAreActiveMLSClients_MockValue = false

        let testCases: [(migrationState: Scaffolding.MigrationState, supportedProtocols: Set<WireAPI.MessageProtocol>)] = [
            (migrationState: .disabled, supportedProtocols: [.mls]),
            (migrationState: .notStarted, supportedProtocols: [.proteus]),
            (migrationState: .ongoing, supportedProtocols: [.proteus]),
            (migrationState: .finalised, supportedProtocols: [.mls])
        ]

        for testCase in testCases {
            await setup(migrationState: testCase.migrationState)
            // When
            try await sut.invoke()
            let pushedProtocols = try XCTUnwrap(mockSelfUserAPI.pushSupportedProtocols_Invocations.last)
            // Then
            XCTAssertEqual(testCase.supportedProtocols, pushedProtocols)
        }
    }

    // MARK: - Setup

    @discardableResult
    private func setup(allActiveMLSClients: Bool) async throws -> ZMUser {
        await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: UUID(), domain: nil, in: context)

            let selfClient = modelHelper.createSelfClient(in: context)
            selfClient.lastActiveDate = Date(timeIntervalSinceNow: -.oneDay)
            selfClient.mlsPublicKeys = randomMLSPublicKeys()

            let otherClient = modelHelper.createClient(for: selfUser)
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
            
            return selfUser
        }
    }

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
