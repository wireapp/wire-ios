//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class PullEventsServiceTests: XCTestCase {
    private var sut: PullEventsService!
    private var updateEventsLocalStore: MockUpdateEventsLocalStoreProtocol!
    private var userClientsLocalStore: MockUserClientsLocalStoreProtocol!
    private var eventsSync: MockPullPendingUpdateEventsSyncProtocol!
    private var generateNotificationService: MockGenerateNotificationServiceProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    
    override func setUp() async throws {
        updateEventsLocalStore = MockUpdateEventsLocalStoreProtocol()
        userClientsLocalStore = MockUserClientsLocalStoreProtocol()
        eventsSync = MockPullPendingUpdateEventsSyncProtocol()
        generateNotificationService = MockGenerateNotificationServiceProtocol()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        
        let generateNotificationProvider = MockenerateNotificationProvider(
            mockGenerateNotificationService: generateNotificationService
        )
        
        sut = PullEventsService(
            coreData: stack,
            userClientsLocalStore: userClientsLocalStore,
            updateEventsLocalStore: updateEventsLocalStore,
            pendingEventsSync: eventsSync,
            generateNotificationProvider: generateNotificationProvider
        )
    }
    
    override func tearDown() async throws {
        stack = nil
        sut = nil
        eventsSync = nil
        generateNotificationService = nil
        updateEventsLocalStore = nil
        userClientsLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }
    
    func testStartsSync_It_Invokes_Methods() async throws {
        
        // Mock
        updateEventsLocalStore.lastEventID_MockValue = .some(nil)
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }
        eventsSync.pull_MockValue = AsyncStream {
            []
        }
        generateNotificationService.process_MockMethod = {}
        
        // When
        try await sut.startSync(
            newEventID: Scaffolding.newEventID
        )
        
        // Then
        XCTAssertEqual(updateEventsLocalStore.lastEventID_Invocations.count, 1)
        XCTAssertEqual(updateEventsLocalStore.lastEventID_Invocations.count, 1)
        XCTAssertEqual(updateEventsLocalStore.storeLastEventIDId_Invocations.count, 1)
        XCTAssertEqual(eventsSync.pull_Invocations.count, 1)
        XCTAssertEqual(generateNotificationService.process_Invocations.count, 1)
    }
    
    func testStartsSync_It_Throws_Error() async throws {
        // Mock
        
        enum MockError: Error {
            case someError
        }
        
        updateEventsLocalStore.lastEventID_MockValue = .some(nil)
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }
        eventsSync.pull_MockError = MockError.someError
        generateNotificationService.process_MockMethod = {}
        
        do {
            // When
            try await sut.startSync(
                newEventID: Scaffolding.newEventID
            )
            
        } catch {
            XCTAssert(error is PullEventsService.Failure)
        }
    }
    
    struct MockenerateNotificationProvider: GenerateNotificationProvider {
        let mockGenerateNotificationService: MockGenerateNotificationServiceProtocol
        
        func generateNotificationService(
            eventsStream: AsyncStream<[WireAPI.UpdateEvent]>
        ) -> WireDomain.GenerateNotificationServiceProtocol {
            mockGenerateNotificationService
        }
    }
    
    private enum Scaffolding {
        static let newEventID = UUID.mockID2
    }
    
}


