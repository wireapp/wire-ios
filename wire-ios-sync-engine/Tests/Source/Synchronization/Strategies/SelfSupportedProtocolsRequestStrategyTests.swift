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
import WireRequestStrategySupport
@testable import WireSyncEngine
import WireSyncEngineSupport

import XCTest

final class SelfSupportedProtocolsRequestStrategyTests: XCTestCase {

    // the api version is just required to build and not influence the tests
    private let defaultAPIVersion: APIVersion = .v5

    private var coreDataStackHelper: CoreDataStackHelper!
    private var mockCoreDataStack: CoreDataStack!

    private var mockUserRepository: MockUserRepositoryProtocol!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        // init mocks

        coreDataStackHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataStackHelper.createStack()
        mockUserRepository = MockUserRepositoryProtocol()

        // set values

        let context = mockCoreDataStack.syncContext
        await context.perform {
            self.mockUserRepository.fetchSelfUser_MockValue = self.createUser(in: context)
        }
    }

    override func tearDown() async throws {
        mockUserRepository = nil
        mockCoreDataStack = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil

        try await super.tearDown()
    }

    func testConfigurationsAllowsSlowSync() {
        // given
        let strategy = makeStrategy()

        // when
        // then
        XCTAssertEqual(strategy.configuration, [.allowsRequestsDuringSlowSync])
    }

    func testApplicationStatusIsSet() {
        // given
        let mockApplicationStatus = MockApplicationStatus()
        let strategy = makeStrategy(applicationStatus: mockApplicationStatus)

        // when
        // then
        XCTAssertNotNil(strategy.applicationStatus)
    }

    func testNextRequestIfAllowed_givenInvalidSyncPhase_thenRequestIsNil() {
        // given
        let mockSyncProgress = MockSyncProgress()
        mockSyncProgress.currentSyncPhase = .done

        let strategy = makeStrategy(syncProgress: mockSyncProgress)

        // when
        let request = strategy.nextRequestIfAllowed(for: defaultAPIVersion)

        // then
        XCTAssertNil(request)
    }

    func testNextRequestIfAllowed_givenValidSyncPhase_thenRequestIsNotNil() async {
        // given
        let mockSyncProgress = MockSyncProgress()
        mockSyncProgress.currentSyncPhase = .updateSelfSupportedProtocols

        let strategy = makeStrategy(syncProgress: mockSyncProgress)

        // when
        let request = await syncContext.perform {
            self.mockUserRepository.fetchSelfUser().supportedProtocols = [.proteus]
            return strategy.nextRequestIfAllowed(for: self.defaultAPIVersion)
        }

        // then
        XCTAssertNotNil(request)
    }

    // MARK: Helpers

    private func makeStrategy(
        applicationStatus: ApplicationStatus? = nil,
        syncProgress: SyncProgress? = nil
    ) -> SelfSupportedProtocolsRequestStrategy {
        SelfSupportedProtocolsRequestStrategy(
            context: syncContext,
            applicationStatus: applicationStatus ?? MockApplicationStatus(),
            syncProgress: syncProgress ?? MockSyncProgress(),
            userRepository: mockUserRepository
        )
    }

    private func createUser(in context: NSManagedObjectContext) -> ZMUser {
        let user = ZMUser(context: context)
        user.remoteIdentifier = UUID()

        return user
    }
}
