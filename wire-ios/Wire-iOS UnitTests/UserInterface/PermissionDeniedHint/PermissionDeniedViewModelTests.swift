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

final class PermissionDeniedViewModelTests: XCTestCase {

    func testNotificationDisplayState() {
        typealias RegistrationPushAccessDenied = L10n.Localizable.Registration.PushAccessDenied

        let sut = PermissionDeniedViewModel(permissionType: .notifications)

        XCTAssertEqual(
            sut.displayState,
            PermissionDeniedViewModel.DisplayState(
                permissionType: .notifications,
                title: RegistrationPushAccessDenied.Hero.title,
                message: RegistrationPushAccessDenied.Hero.paragraph1,
                primaryButtonTitle: RegistrationPushAccessDenied.SettingsButton.title.capitalized,
                secondaryButtonTitle: RegistrationPushAccessDenied.MaybeLaterButton.title.capitalized
            )
        )
    }

    func testActionsForNotificationEvents() {
        let sut = PermissionDeniedViewModel(permissionType: .notifications)

        XCTAssertEqual(
            sut.action(for: .primaryButtonTapped),
            .openSettings(permissionType: .notifications)
        )
        XCTAssertEqual(
            sut.action(for: .secondaryButtonTapped),
            .skip(permissionType: .notifications)
        )
    }
}
