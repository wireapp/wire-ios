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

final class ProfileHeaderViewModelTests: XCTestCase {

    func testDisplayStateShowsProfileTextsForSelfUser() {
        let user = MockUserType.createSelfUser(name: "Alice", inTeam: UUID())
        user.handle = "alice"
        user.teamName = "Wire"
        user.availability = .available

        let sut = ProfileHeaderViewModel(
            user: user,
            viewer: user,
            conversation: nil,
            options: [.allowEditingAvailability, .allowEditingProfilePicture]
        )

        XCTAssertEqual(sut.displayState.handleText, "@alice")
        XCTAssertEqual(sut.displayState.teamNameText, "Wire")
        XCTAssertFalse(sut.displayState.isAvailabilityHidden)
        XCTAssertTrue(sut.displayState.isProfilePictureEditingEnabled)
        XCTAssertFalse(sut.displayState.isQRCodeButtonHidden)
    }

    func testDisplayStateHidesUnavailableSections() {
        let viewer = MockUserType.createSelfUser(name: "Viewer", inTeam: UUID())
        let user = MockUserType.createUser(name: "Alice")
        user.handle = nil
        user.teamName = "Wire"
        user.availability = .none

        let sut = ProfileHeaderViewModel(
            user: user,
            viewer: viewer,
            conversation: nil,
            options: [.hideTeamName]
        )

        XCTAssertNil(sut.displayState.handleText)
        XCTAssertNil(sut.displayState.teamNameText)
        XCTAssertTrue(sut.displayState.isAvailabilityHidden)
        XCTAssertTrue(sut.displayState.isQRCodeButtonHidden)
    }

    func testAvailabilitySelectionRequestsAvailabilityUpdate() {
        let user = MockUserType.createSelfUser(name: "Alice")
        let sut = ProfileHeaderViewModel(user: user, viewer: user, conversation: nil, options: [])

        guard case let .updateAvailability(availability) = sut.availabilitySelected(.busy) else {
            return XCTFail("Expected updateAvailability action")
        }

        XCTAssertEqual(availability, .busy)
    }

    func testQRCodeButtonVisibilityRequiresSelfUserAndFeatureFlag() {
        let user = MockUserType.createSelfUser(name: "Alice")
        let sut = ProfileHeaderViewModel(user: user, viewer: user, conversation: nil, options: [])

        XCTAssertTrue(sut.isQRCodeButtonHidden(isFeatureEnabled: false))
        XCTAssertFalse(sut.isQRCodeButtonHidden(isFeatureEnabled: true))
    }
}
