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

import XCTest

@testable import Wire

final class ConversationConnectAvatarViewModeTests: XCTestCase {
    var sut: ConversationConnectAvatarView!
    var otherUser: MockUserType!
    var users: [any UserType]!

    override func setUp() {
        super.setUp()

        users = []

        otherUser = MockUserType.createDefaultOtherUser()
        sut = ConversationConnectAvatarView()
    }

    override func tearDown() {
        sut = nil
        users = []
        otherUser = nil

        super.tearDown()
    }

    func testThatModeIsOneWhenGroupConversationWithOneServiceUser() {
        // GIVEN
        let mockServiceUser = MockServiceUserType()
        mockServiceUser.serviceIdentifier = "serviceIdentifier"
        mockServiceUser.providerIdentifier = "providerIdentifier"
        XCTAssert(mockServiceUser.isApp_)

        users = [mockServiceUser]

        // WHEN
        sut.configure(context: ConversationConnectAvatarView.Context(
            users: users
        ))

        // THEN
        XCTAssertEqual(sut.mode, .one(serviceUser: true))
    }

    func testThatModeIsNoneWhenGroupConversationIsEmpty() {
        // GIVEN

        // WHEN
        sut.configure(context: ConversationConnectAvatarView.Context(
            users: users
        ))

        // THEN
        XCTAssertEqual(sut.mode, .none)
    }
}
