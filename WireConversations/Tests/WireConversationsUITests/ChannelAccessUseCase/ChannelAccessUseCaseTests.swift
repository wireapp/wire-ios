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

import WireConversationsImplementation
import XCTest

final class ChannelAccessUseCaseTests: XCTestCase {

    func testInit_withNilPermission_setsPublicAccessLevel() {
        let useCase = ChannelAccessUseCase(permission: nil)

        XCTAssertEqual(useCase.settings.accessLevel, .public)
        XCTAssertNil(useCase.settings.participantPermission)
    }

    func testInit_withPermission_setsPrivateAccessLevelAndPermissionAdmins() {
        let useCase = ChannelAccessUseCase(permission: .admins)

        XCTAssertEqual(useCase.settings.accessLevel, .private)
        XCTAssertEqual(useCase.settings.participantPermission, .admins)
    }

    func testInit_withPermission_setsPrivateAccessLevelAndPermissionAdminAndMemeber() {
        let useCase = ChannelAccessUseCase(permission: .adminsAndMembers)

        XCTAssertEqual(useCase.settings.accessLevel, .private)
        XCTAssertEqual(
            useCase.settings.participantPermission,
            .adminsAndMembers
        )
    }

    func testUpdateParticipantPermission_changesPermission() {
        let useCase = ChannelAccessUseCase(permission: .admins)
        useCase.updateParticipantPermission(to: .adminsAndMembers)

        XCTAssertEqual(useCase.settings.participantPermission, .adminsAndMembers)
    }

    func testUpdateParticipantPermission_changesFromPublicToPrivate() {
        let useCase = ChannelAccessUseCase(permission: nil) // means public
        XCTAssertEqual(useCase.settings.accessLevel, .public)

        useCase.updateAccessLevel(to: .private)

        XCTAssertEqual(useCase.settings.participantPermission, .adminsAndMembers)
        XCTAssertEqual(useCase.settings.accessLevel, .private)
    }

}
