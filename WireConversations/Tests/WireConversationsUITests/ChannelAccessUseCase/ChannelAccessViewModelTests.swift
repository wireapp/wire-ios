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
@testable import WireConversationsUI
@testable import WireConversationsAPI
@testable import WireConversationsImplementationSupport

final class ChannelAccessViewModelTests: XCTestCase {

    var viewModel: ChannelAccessViewModel!
    var useCase: MockChannelAccessUseCaseProtocol!

    override func setUp() {
        super.setUp()

        let initialSettings = ChannelAccessSettings(
            accessLevel: .public,
            participantPermission: .adminsAndMembers
        )

        useCase = MockChannelAccessUseCaseProtocol()
        useCase.underlyingSettings = initialSettings
        viewModel = ChannelAccessViewModel(accentColor: .red, useCase: useCase)
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func test_selectAccessLevel_toPrivate_triggersConfirmation() {
        viewModel.selectAccessLevel(.private)
        XCTAssertTrue(viewModel.showPrivateAccessConfirmation)
        XCTAssertEqual(
            viewModel.settings.participantPermission,
            .adminsAndMembers
        )
    }

    func test_selectAccessLevel_toSameLevel_doesNotTriggerConfirmation() {
        useCase.updateAccessLevelTo_MockMethod = { _ in  }
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 0)
        viewModel.selectAccessLevel(.public)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.first, .public)
        XCTAssertFalse(viewModel.showPrivateAccessConfirmation)
    }

    func test_confirmPrivateAccessChange_setsAccessToPrivate() {
        useCase.updateAccessLevelTo_MockMethod = { _ in  }
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 0)
        
        viewModel.selectAccessLevel(.private)
        viewModel.confirmPrivateAccessChange()
        
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateAccessLevelTo_Invocations.first, .private)
        XCTAssertEqual(viewModel.settings.accessLevel, .private)
    }

    func test_selectParticipantPermission_updatesState() {
        useCase.updateParticipantPermissionTo_MockMethod = { _ in  }
        viewModel.selectParticipantPermission(.adminsAndMembers)
        XCTAssertEqual(viewModel.settings.participantPermission, .adminsAndMembers)
        XCTAssertEqual(useCase.updateParticipantPermissionTo_Invocations.count, 1)
        XCTAssertEqual(useCase.updateParticipantPermissionTo_Invocations.first, .adminsAndMembers)
    }
}
