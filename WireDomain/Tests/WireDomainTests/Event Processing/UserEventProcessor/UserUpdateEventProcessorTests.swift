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
@testable import WireDomain
import WireDomainSupport
import XCTest

final class UserUpdateEventProcessorTests: XCTestCase {

    var sut: UserUpdateEventProcessor!
    var userRepository: MockUserRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        userRepository = MockUserRepositoryProtocol()
        sut = UserUpdateEventProcessor(repository: userRepository)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        userRepository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Update_User_Repo_Method() async throws {
        // Given

        let event = UserUpdateEvent(
            id: Scaffolding.userID,
            userID: UserID(uuid: Scaffolding.userID, domain: Scaffolding.domain),
            accentColorID: nil,
            name: "username",
            handle: "test",
            email: "test@wire.com",
            isSSOIDDeleted: nil,
            assets: nil,
            supportedProtocols: [.proteus, .mls]
        )

        // Mock

        userRepository.updateUserFrom_MockMethod = { _ in }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(userRepository.updateUserFrom_Invocations, [event])
    }

    private enum Scaffolding {
        static let userID = UUID()
        static let domain = "domain.com"
    }

}
