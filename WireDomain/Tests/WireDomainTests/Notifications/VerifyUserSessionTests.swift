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
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class VerifyUserSessionTests: XCTestCase {
    private var sut: VerifyUserSession!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var cookieStorage: MockCookieStorageProtocol!
    private var pullEventsService: MockPullEventsServiceProtocol!
    
    override func setUp() async throws {
        userLocalStore = MockUserLocalStoreProtocol()
        cookieStorage = MockCookieStorageProtocol()
        pullEventsService = MockPullEventsServiceProtocol()
        let mockPullEventsServiceProvider = MockPullEventsServiceProvider(
            pullEventsService: pullEventsService
        )
        
        sut = VerifyUserSession(
            pullEventsServiceProvider: mockPullEventsServiceProvider,
            userLocalStore: userLocalStore,
            cookieStorage: cookieStorage
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        userLocalStore = nil
        cookieStorage = nil
        pullEventsService = nil
    }
    
    func testVerify_It_Invokes_Methods_And_Call_Completion_Block() async throws {
        
        // Mock
        
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        cookieStorage.fetchCookies_MockValue = [validCookie]
              
        var completionCalledCount = 0
        
        let completion: () async throws -> Void = {
            completionCalledCount += 1
        }
        
        // When
        try await sut.verify(
            userID: Scaffolding.userID,
            then: completion
        )
        
        // Then
        XCTAssertEqual(completionCalledCount, 1)
        XCTAssertEqual(cookieStorage.fetchCookies_Invocations.count, 1)
        
    }
    
    func testVerify_It_Throws_User_Unauthenticated_Error() async throws {
        
        // Mock
        
        cookieStorage.fetchCookies_MockValue = [.init()]
        
        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSession.Failure.userUnauthenticated) { [self] in
            // When
            try await sut.verify(
                userID: Scaffolding.userID,
                then: {}
            )
        }
        
    }
    
    func testStartSyncingEvents_It_Invokes_Methods() async throws {
        // Mock
        userLocalStore.selfUserInfo_MockValue = (UUID.mockID1, UUID.mockID1.uuidString)
        pullEventsService.startSyncNewEventID_MockMethod = { _ in }
        
        // When
        try await sut.startSyncingEvents(eventID: .mockID1)
        
        // Then
        XCTAssertEqual(userLocalStore.selfUserInfo_Invocations.count, 1)
        XCTAssertEqual(pullEventsService.startSyncNewEventID_Invocations.count, 1)
    }
    
    func testStartSyncingEvents_It_Throws_Missing_User_Client_Error() async throws {
        // Mock
        userLocalStore.selfUserInfo_MockValue = (UUID.mockID1, nil)
        
        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSession.Failure.missingUserClient) { [self] in
            // When
            try await sut.startSyncingEvents(eventID: .mockID1)
        }
    }
    
    private struct MockPullEventsServiceProvider: PullEventsServiceProvider {
        let pullEventsService: MockPullEventsServiceProtocol
        
        func pullEventsService(
            selfUserID: UUID,
            selfClientID: String
        ) async -> any WireDomain.PullEventsServiceProtocol {
            pullEventsService
        }
    }
    
    private enum Scaffolding {
        static let userID = UUID.mockID1
        static let validCookie = HTTPCookie(properties: [
            .name: "zuid",
            .path: "some path",
            .value: "some value",
            .domain: "some domain",
            .expires: Date.distantFuture
        ])
    }
    
}


