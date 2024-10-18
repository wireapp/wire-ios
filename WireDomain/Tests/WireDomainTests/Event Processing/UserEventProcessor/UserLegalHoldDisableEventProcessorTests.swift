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
@testable import WireDomain
import WireDomainSupport
import XCTest

final class UserLegalHoldDisableEventProcessorTests: XCTestCase {

    private var sut: UserLegalholdDisableEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        userRepository = MockUserRepositoryProtocol()
        sut = UserLegalholdDisableEventProcessor(
            repository: userRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        userRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Disable_User_Legalhold_Repo_Method() async throws {
        // Mock

        userRepository.disableUserLegalHold_MockMethod = {}

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.disableUserLegalHold_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = UserLegalholdDisableEvent(
            userID: UUID()
        )
    }

}
