////
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

import Foundation
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

final class ProteusToMLSMigrationCoordinatorTests: ZMBaseManagedObjectTest {

    // MARK: - Properties

    var sut: ProteusToMLSMigrationCoordinator!
    var mockStorage: MockProteusToMLSMigrationStorageInterface!
    var mockFeatureRepository: MockFeatureRepositoryInterface!
    var mockActionsProvider: MockMLSActionsProviderProtocol!
    var mockMLSService: MockMLSServiceInterface!
    var mockPostProtocolChangeUpdater: MockConversationPostProtocolChangeUpdating!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        mockStorage = MockProteusToMLSMigrationStorageInterface()
        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockActionsProvider = MockMLSActionsProviderProtocol()
        mockMLSService = MockMLSServiceInterface()
        mockPostProtocolChangeUpdater = MockConversationPostProtocolChangeUpdating()

        sut = ProteusToMLSMigrationCoordinator(
            context: syncMOC,
            storage: mockStorage,
            featureRepository: mockFeatureRepository,
            actionsProvider: mockActionsProvider,
            postProtocolChangeUpdater: mockPostProtocolChangeUpdater
        )

        syncMOC.performAndWait {
            syncMOC.mlsService = mockMLSService
        }

        // Set default mocks
        mockActionsProvider.syncUsersQualifiedIDsContext_MockMethod = { _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = true
        mockMLSService.joinGroupWith_MockMethod = { _ in }
        mockFeatureRepository.fetchMLSMigration_MockValue = .init()
        mockPostProtocolChangeUpdater.updateLocalConversationQualifiedIDToContext_MockMethod = { _, _, _, _ in }

        BackendInfo.storage = .temporary()
        DeveloperFlag.storage = .temporary()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockStorage = nil
        mockFeatureRepository = nil
        mockActionsProvider = nil
        mockMLSService = nil
        mockPostProtocolChangeUpdater = nil
        BackendInfo.storage = .standard
        DeveloperFlag.storage = .standard
        super.tearDown()
    }

    // MARK: - Migration Start

    func test_ItStartsMigration_IfNotStartedAndReady() async throws {
        // GIVEN
        await createUserAndGroupConversation()

        setMigrationReadiness(to: true)
        mockStorage.underlyingMigrationStatus = .notStarted

        var startedMigration = false
        mockMLSService.startProteusToMLSMigration_MockMethod = {
            startedMigration = true
        }

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockStorage.underlyingMigrationStatus, .started)
        XCTAssertTrue(startedMigration)
    }

    func test_ItDoesntStartMigration_IfAlreadyStarted() async throws {
        // GIVEN
        await createUserAndGroupConversation()

        setMigrationReadiness(to: true)
        mockStorage.underlyingMigrationStatus = .started
        mockMLSService.conversationExistsGroupID_MockMethod = { _ in return true }

        var startedMigration = false
        mockMLSService.startProteusToMLSMigration_MockMethod = {
            startedMigration = true
        }

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockStorage.underlyingMigrationStatus, .started)
        XCTAssertFalse(startedMigration)
    }

    func test_ItDoesntStartMigration_IfNotReady() async throws {
        // GIVEN
        await createUserAndGroupConversation()

        setMigrationReadiness(to: false)
        mockStorage.underlyingMigrationStatus = .notStarted

        var startedMigration = false
        mockMLSService.startProteusToMLSMigration_MockMethod = {
            startedMigration = true
        }

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockStorage.underlyingMigrationStatus, .notStarted)
        XCTAssertFalse(startedMigration)
    }

    // MARK: - Migration finalisation

    func test_ItSyncsUsers_IfFinalisationTimeHasNotBeenReached() async throws {
        // GIVEN
        mockStorage.underlyingMigrationStatus = .started
        await createUserAndGroupConversation()

        // Mock that the finalisation time has not been reached
        mockFeatureRepository.fetchMLSMigration_MockValue = Feature.MLSMigration(
            status: .enabled,
            config: .init(finaliseRegardlessAfter: .distantFuture)
        )

        // Insert users in the context
        let qualifiedIDs = await syncMOC.perform { [syncMOC] in
            let user1 = ZMUser.insertNewObject(in: syncMOC)
            user1.remoteIdentifier = .create()
            user1.domain = "domain.com"

            let user2 = ZMUser.insertNewObject(in: syncMOC)
            user2.remoteIdentifier = .create()
            user2.domain = "domain.com"

            return [user1.qualifiedID, user2.qualifiedID]
        }

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockActionsProvider.syncUsersQualifiedIDsContext_Invocations.count, 1)

        let invocation = try XCTUnwrap(
            mockActionsProvider.syncUsersQualifiedIDsContext_Invocations.first
        )

        // Assert the users has been synced
        XCTAssertEqual(Set(invocation.qualifiedIDs), Set(qualifiedIDs))
    }

    func test_ItJoinsMLSGroup_IfGroupDoesntExist() async throws {
        // GIVEN
        let groupID = MLSGroupID.random()
        await createUserAndGroupConversation(groupID: groupID)

        mockStorage.underlyingMigrationStatus = .started
        mockMLSService.conversationExistsGroupID_MockValue = false

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockMLSService.joinGroupWith_Invocations.count, 1)
        XCTAssertEqual(mockMLSService.joinGroupWith_Invocations.first, groupID)
    }

    func test_ItDoesntJoinMLSGroup_IfGroupExists() async throws {
        // GIVEN
        await createUserAndGroupConversation()
        mockStorage.underlyingMigrationStatus = .started
        mockMLSService.conversationExistsGroupID_MockValue = true

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        XCTAssertEqual(mockMLSService.joinGroupWith_Invocations.count, 0)
    }

    func test_ItUpdatesConversationProtocolToMLS_IfAllParticipantsSupportMLS() async throws {
        // GIVEN
        mockStorage.underlyingMigrationStatus = .started

        await setMocksForFinalisation(
            supportedProtocolForAllParticipants: .mls,
            finaliseRegardlessAfter: nil
        )

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        // TODO: Assert we update the conversation protocol
        // https://wearezeta.atlassian.net/browse/WPB-542
    }

    func test_ItUpdatesConversationProtocolToMLS_IfFinalisationTimeHasBeenReached() async throws {
        // GIVEN
        mockStorage.underlyingMigrationStatus = .started

        await setMocksForFinalisation(
            supportedProtocolForAllParticipants: .proteus,
            finaliseRegardlessAfter: .distantPast
        )

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        // TODO: Assert we update the conversation protocol
        // https://wearezeta.atlassian.net/browse/WPB-542
    }

    func test_ItDoesntUpdateProtocolToMLS_IfParticipantsDontSupportMLS_AndFinalisationTimeHasNotBeenReached() async throws {
        // GIVEN
        mockStorage.underlyingMigrationStatus = .started

        await setMocksForFinalisation(
            supportedProtocolForAllParticipants: .proteus,
            finaliseRegardlessAfter: .distantFuture
        )

        // WHEN
        try await sut.updateMigrationStatus()

        // THEN
        // TODO: Assert we don't update the conversation protocol
        // https://wearezeta.atlassian.net/browse/WPB-542
    }

    // MARK: - Helpers

    private typealias MigrationStartStatus = ProteusToMLSMigrationCoordinator.MigrationStartStatus

    private func setMocksForFinalisation(
        supportedProtocolForAllParticipants protocol: MessageProtocol,
        finaliseRegardlessAfter: Date?
    ) async {
        // Create self user and conversation
        let (selfUser, conversation) = await createUserAndGroupConversation()

        // Create an additional user, add users to the conversation, and set supported protocols on both users
        await syncMOC.perform { [syncMOC] in
            let user = ZMUser.insertNewObject(in: syncMOC)

            // TODO: Set supported protocols on the users
            // https://wearezeta.atlassian.net/browse/WPB-542
            //
            // user.supportedProtocols = [protocol]
            // selfUser.supportedProtocols = [protocol]

            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        }

        // Set finalisation time
        mockFeatureRepository.fetchMLSMigration_MockValue = .init(
            status: .enabled,
            config: .init(finaliseRegardlessAfter: finaliseRegardlessAfter)
        )
    }

    @discardableResult
    private func createUserAndGroupConversation(
        groupID: MLSGroupID = .random()
    ) async -> (ZMUser, ZMConversation) {

        return await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.teamIdentifier = UUID()

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.teamRemoteIdentifier = selfUser.teamIdentifier
            conversation.conversationType = .group
            conversation.messageProtocol = .mixed
            conversation.mlsGroupID = groupID

            return (selfUser, conversation)
        }
    }

    private func setMigrationReadiness(to ready: Bool) {
        setMockValues(
            isAPIV5Supported: ready,
            isClientSupportingMLS: ready,
            isBackendSupportingMLS: ready,
            isMLSProtocolSupported: ready,
            isMLSMigrationFeatureEnabled: ready,
            hasStartTimeBeenReached: ready
        )
    }

    private func setMigrationReadiness(for status: ProteusToMLSMigrationCoordinator.MigrationStartStatus) {
        switch status {
        case .canStart:
            setMigrationReadiness(to: true)
        case .cannotStart(reason: let reason):
            setMockValues(
                isAPIV5Supported: reason != .unsupportedAPIVersion,
                isClientSupportingMLS: reason != .clientDoesntSupportMLS,
                isBackendSupportingMLS: reason != .backendDoesntSupportMLS,
                isMLSProtocolSupported: reason != .mlsProtocolIsNotSupported,
                isMLSMigrationFeatureEnabled: reason != .mlsMigrationIsNotEnabled,
                hasStartTimeBeenReached: reason != .startTimeHasNotBeenReached
            )
        }
    }

    private func setMockValues(
        isAPIV5Supported: Bool,
        isClientSupportingMLS: Bool,
        isBackendSupportingMLS: Bool,
        isMLSProtocolSupported: Bool,
        isMLSMigrationFeatureEnabled: Bool,
        hasStartTimeBeenReached: Bool
    ) {
        // Set APIVersion
        BackendInfo.apiVersion = isAPIV5Supported ? .v5 : .v0

        // Set MLS flag
        var flag = DeveloperFlag.enableMLSSupport
        flag.isOn = isClientSupportingMLS

        // Set backend support for MLS
        if isBackendSupportingMLS {
            mockActionsProvider.fetchBackendPublicKeysIn_MockValue = BackendMLSPublicKeys()
            mockActionsProvider.fetchBackendPublicKeysIn_MockError = nil
        } else {
            mockActionsProvider.fetchBackendPublicKeysIn_MockValue = nil
            mockActionsProvider.fetchBackendPublicKeysIn_MockError = FetchBackendMLSPublicKeysAction.Failure.mlsNotEnabled
        }

        // Set MLS feature
        mockFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(supportedProtocols: isMLSProtocolSupported ? [.mls] : [])
        )

        // Set MLS Migration feature
        let startTime: Date = hasStartTimeBeenReached ? .distantPast : .distantFuture
        mockFeatureRepository.fetchMLSMigration_MockValue = Feature.MLSMigration(
            status: isMLSMigrationFeatureEnabled ? .enabled : .disabled,
            config: .init(startTime: startTime)
        )
    }

}
