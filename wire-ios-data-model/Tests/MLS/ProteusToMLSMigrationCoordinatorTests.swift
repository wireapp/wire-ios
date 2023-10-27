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

class ProteusToMLSMigrationCoordinatorTests: ZMBaseManagedObjectTest {

    var sut: ProteusToMLSMigrationCoordinator!
    var mockStorage: MockProteusToMLSMigrationStorageInterface!
    var mockFeatureRepository: MockFeatureRepositoryInterface!
    var mockActionsProvider: MockMLSActionsProviderProtocol!
    var mockMLSService: MockMLSService!

    override func setUp() {
        super.setUp()

        mockStorage = MockProteusToMLSMigrationStorageInterface()
        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockActionsProvider = MockMLSActionsProviderProtocol()
        mockMLSService = MockMLSService()

        sut = ProteusToMLSMigrationCoordinator(
            context: syncMOC,
            storage: mockStorage,
            featureRepository: mockFeatureRepository,
            actionsProvider: mockActionsProvider
        )

        syncMOC.mlsService = mockMLSService

        BackendInfo.storage = .random()!
        DeveloperFlag.storage = .random()!
    }

    override func tearDown() {
        sut = nil
        mockStorage = nil
        mockFeatureRepository = nil
        mockActionsProvider = nil
        mockMLSService = nil
        BackendInfo.storage = .standard
        DeveloperFlag.storage = .standard
        super.tearDown()
    }

    // MARK: - UpdateMigrationStatus

    func test_UpdateMigrationStatus_StartsMigration_IfNotStartedAndReady() {
        // Given
        setMigrationReadiness(to: true)
        mockStorage.underlyingMigrationStatus = .notStarted

        let expectation = XCTestExpectation(description: "started migration")
        mockMLSService.startProteusToMLSMigrationMock = {
            expectation.fulfill()
        }

        // When
        sut.updateMigrationStatus()

        // Then
        wait(for: [expectation], timeout: 0.5)
    }

    func test_UpdateMigrationStatus_DoesntStartMigration_IfAlreadyStarted() {
        // Given
        setMigrationReadiness(to: true)
        mockStorage.underlyingMigrationStatus = .started

        let expectation = XCTestExpectation(description: "started migration")
        expectation.isInverted = true
        mockMLSService.startProteusToMLSMigrationMock = {
            expectation.fulfill()
        }

        // When
        sut.updateMigrationStatus()

        // Then
        wait(for: [expectation], timeout: 0.5)
    }

    func test_UpdateMigrationStatus_DoesntStartMigration_IfNotReady() {
        // Given
        setMigrationReadiness(to: false)
        mockStorage.underlyingMigrationStatus = .notStarted

        let expectation = XCTestExpectation(description: "started migration")
        expectation.isInverted = true
        mockMLSService.startProteusToMLSMigrationMock = {
            expectation.fulfill()
        }

        // When
        sut.updateMigrationStatus()

        // Then
        wait(for: [expectation], timeout: 0.5)
    }

    // MARK: - StartMigrationIfNeeded

    func test_StartMigrationIfNeeded_SetsMigrationStatus() async {
        // Given
        setMigrationReadiness(to: true)

        // When
        await sut.startMigrationIfNeeded()

        // Then
        mockStorage.underlyingMigrationStatus = .started
    }

    // MARK: - ResolveMigrationStartStatus

    func test_ResolveMigrationStartStatus() async {
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .canStart)
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .unsupportedAPIVersion))
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .clientDoesntSupportMLS))
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .backendDoesntSupportMLS))
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .mlsProtocolIsNotSupported))
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .mlsMigrationIsNotEnabled))
        await test_ResolveMigrationStartStatus_ResolvesTo(status: .cannotStart(reason: .startTimeHasNotBeenReached))
    }

    private func test_ResolveMigrationStartStatus_ResolvesTo(status: MigrationStartStatus) async {
        // Given
        setMigrationReadiness(for: status)

        // When / Then
        let resolvedStatus = await sut.resolveMigrationStartStatus()

        // Then
        XCTAssertEqual(resolvedStatus, status)
    }

    // MARK: - Helpers

    private typealias MigrationStartStatus = ProteusToMLSMigrationCoordinator.MigrationStartStatus

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
