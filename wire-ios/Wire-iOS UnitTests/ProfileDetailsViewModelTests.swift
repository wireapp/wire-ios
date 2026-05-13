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

import XCTest

@testable import Wire

final class ProfileDetailsViewModelTests: XCTestCase {

    func testDisplayStateShowsRichProfileAndReadReceiptsForOneToOneConversation() {
        let teamID = UUID()
        let viewer = MockUserType.createSelfUser(name: "Viewer", inTeam: teamID)
        viewer.readReceiptsEnabled = true

        let user = MockUserType.createConnectedUser(name: "Alice", inTeam: teamID)
        user.emailAddress = "alice@example.com"
        user.richProfile = [UserRichProfileField(type: "Title", value: "Engineer")]

        let conversation = MockConversation.oneOnOneConversation().convertToRegularConversation()

        let sut = ProfileDetailsViewModel(user: user, viewer: viewer, conversation: conversation)

        XCTAssertEqual(sut.displayState.sections.map(\.content), [
            .richProfile([
                UserRichProfileField(type: "Email", value: "alice@example.com"),
                UserRichProfileField(type: "Title", value: "Engineer")
            ]),
            .readReceiptsStatus(enabled: true)
        ])
        XCTAssertEqual(sut.displayState.sections[0].headerAccessibilityIdentifier, "InformationHeader")
        XCTAssertEqual(sut.displayState.sections[1].footerAccessibilityIdentifier, "ReadReceiptsStatusFooter")
    }

    func testDisplayStateHidesRichProfileFieldsWhenViewerCannotAccessThem() {
        let viewer = MockUserType.createConnectedUser(name: "Guest", inTeam: nil)
        viewer.isGuestInConversation = true

        let user = MockUserType.createConnectedUser(name: "Alice", inTeam: UUID())
        user.emailAddress = nil
        user.richProfile = [UserRichProfileField(type: "Title", value: "Engineer")]

        let conversation = MockConversation.groupConversation().convertToRegularConversation()

        let sut = ProfileDetailsViewModel(user: user, viewer: viewer, conversation: conversation)

        XCTAssertEqual(sut.displayState.sections, [])
    }

    func testGroupAdminToggleUpdatesDisplayStateAndReturnsAction() {
        let teamID = UUID()
        let viewer = MockUserType.createSelfUser(name: "Viewer", inTeam: teamID)
        viewer.canModifyOtherMemberInConversation = true

        let user = MockUserType.createConnectedUser(name: "Alice", inTeam: teamID)
        user.isGroupAdminInConversation = false

        let conversation = MockConversation.groupConversation().convertToRegularConversation()

        let sut = ProfileDetailsViewModel(user: user, viewer: viewer, conversation: conversation)
        let action = sut.setGroupAdminStatus(true)

        XCTAssertEqual(action, .updateGroupAdminStatus(enabled: true))
        XCTAssertEqual(sut.displayState.sections.first?.content, .groupAdminStatus(enabled: true))

        sut.revertGroupAdminStatus()

        XCTAssertEqual(sut.displayState.sections.first?.content, .groupAdminStatus(enabled: false))
    }
}
