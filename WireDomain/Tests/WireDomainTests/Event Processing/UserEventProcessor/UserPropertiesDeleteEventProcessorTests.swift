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

final class UserPropertiesDeleteEventProcessorTests: XCTestCase {

    private var sut: UserPropertiesDeleteEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        userRepository = MockUserRepositoryProtocol()
        sut = UserPropertiesDeleteEventProcessor(
            repository: userRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        userRepository = nil
        sut = nil
    }

    func testProcessEvent_It_Invokes_Delete_User_Property_Repo_Method() async throws {
        // Given

        let key = UserProperty.Key.wireReceiptMode
        let event = UserPropertiesDeleteEvent(key: key.rawValue)

        // Mock

        userRepository.deleteUserPropertyWithKey_MockMethod = { _ in }

        // When

        await sut.processEvent(event)

        // Then

        XCTAssertEqual(userRepository.deleteUserPropertyWithKey_Invocations, [key])
    }
}
