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
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class ChannelAccessViewModelTests: XCTestCase {

    lazy var viewModel = ChannelAccessViewModel(accentColor: .red, useCase: useCase)

    lazy var useCase = {
        let initialSettings = ChannelAccessSettings(
            accessLevel: .public,
            participantPermission: .everyone
        )

        let useCase = MockChannelAccessUseCaseProtocol()
        useCase.underlyingSettings = initialSettings

        return useCase
    }()

    func test_selectAccessLevel_toPrivate_triggersConfirmation() async {
        await viewModel.selectAccessLevel(.private)
        XCTAssertTrue(viewModel.showPrivateAccessConfirmation)
        XCTAssertEqual(
            viewModel.settings.participantPermission,
            .everyone
        )
    }

    func test_selectAccessLevel_toSameLevel_doesNotTriggerConfirmation() async {
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 0)
        await viewModel.selectAccessLevel(.public)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.first, .public)
        XCTAssertFalse(viewModel.showPrivateAccessConfirmation)
    }

    func test_confirmPrivateAccessChange_setsAccessToPrivate() async {
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 0)

        await viewModel.selectAccessLevel(.private)

        useCase.underlyingSettings = .init(
            accessLevel: .private,
            participantPermission: .everyone
        )

        await viewModel.confirmPrivateAccessChange()

        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.first, .private)
        XCTAssertEqual(viewModel.settings.accessLevel, .private)
        XCTAssertEqual(
            viewModel.settings.participantPermission,
            .everyone
        )
    }

    func test_selectParticipantPermission_updatesState() async {
        await viewModel.selectParticipantPermission(.everyone)
        XCTAssertEqual(viewModel.settings.participantPermission, .everyone)
        XCTAssertEqual(useCase.updateParticipantPermissionTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateParticipantPermissionTo_Invocations.first, .everyone)
    }
}
