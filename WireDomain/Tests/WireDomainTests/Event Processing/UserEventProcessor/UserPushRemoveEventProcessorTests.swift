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

import Foundation
import WireDomainSupport
import XCTest

@testable import WireDomain

final class UserPushRemoveEventProcessorTests: XCTestCase {

    var sut: UserPushRemoveEventProcessor!
    var mockUserRepository: MockUserRepositoryProtocol!
    
    override func setUp() async throws {
        try await super.setUp()
        mockUserRepository = MockUserRepositoryProtocol()
        sut = UserPushRemoveEventProcessor(
            repository: mockUserRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        mockUserRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_Method() async throws {
        // Mock
        
        mockUserRepository.removePushToken_MockMethod = { }
        
        // When

        sut.processEvent()

        // Then

        XCTAssertEqual(mockUserRepository.removePushToken_Invocations.count, 1)
    }

}
