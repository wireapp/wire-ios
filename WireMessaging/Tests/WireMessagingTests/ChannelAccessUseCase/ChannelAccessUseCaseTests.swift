//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireMessagingDomain
import WireMessagingDomainSupport
import XCTest

@MainActor
final class ChannelAccessUseCaseTests: XCTestCase {

    lazy var repo = MockChannelRepositoryProtocol()

    // for channels MVP, only public is supported, comment out for next phase
    // TODO: [WPB-16860] https://wearezeta.atlassian.net/browse/WPB-16860
//    func testInit_withNilPermission_setsPublicAccessLevel() {
//        let useCase = ChannelAccessUseCase(
//            permission: nil,
//            repository: repo
//        )
//
//        XCTAssertEqual(useCase.settings.accessLevel, .public)
//        XCTAssertNil(useCase.settings.participantPermission)
//    }
//
//    func testUpdateParticipantPermission_changesFromPublicToPrivate() async throws {
//        let useCase = ChannelAccessUseCase(permission: nil, repository: repo) // means public
//        XCTAssertEqual(useCase.settings.accessLevel, .public)
//
//        try await useCase.updateAccessLevel(to: .private)
//
//        XCTAssertEqual(useCase.settings.participantPermission, .everyone)
//        XCTAssertEqual(useCase.settings.accessLevel, .private)
//    }

    func testInit_withPermission_setsPrivateAccessLevelAndPermissionAdmins() {
        let useCase = ChannelAccessUseCase(permission: .admins, repository: repo)

        XCTAssertEqual(useCase.settings.accessLevel, .private)
        XCTAssertEqual(useCase.settings.participantPermission, .admins)
    }

    func testInit_withPermission_setsPrivateAccessLevelAndPermissionEveryone() {
        let useCase = ChannelAccessUseCase(permission: .everyone, repository: repo)

        XCTAssertEqual(useCase.settings.accessLevel, .private)
        XCTAssertEqual(
            useCase.settings.participantPermission,
            .everyone
        )
    }

    func testUpdateParticipantPermission_changesPermission() async throws {
        let useCase = ChannelAccessUseCase(permission: .admins, repository: repo)
        repo.updateParticipantPermissionTo_MockValue = .everyone
        let settings = try await useCase.updateParticipantPermission(to: .everyone)

        XCTAssertEqual(settings.participantPermission, .everyone)
    }
}
