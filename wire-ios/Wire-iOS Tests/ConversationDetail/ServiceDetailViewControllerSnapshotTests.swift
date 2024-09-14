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

import WireTestingPackage
import XCTest

@testable import Wire

final class ServiceDetailViewControllerSnapshotTests: CoreDataSnapshotTestCase {

    private var sut: ServiceDetailViewController!
    private var serviceUser: MockServiceUserType!
    private var groupConversation: ZMConversation!
    private var mockSelfUser: MockUserType!
    private var snapshotHelper: SnapshotHelper_!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        serviceUser = .createServiceUser(name: "ServiceUser")
        groupConversation = createGroupConversation()
        mockSelfUser = .createSelfUser(name: "Bob")
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        serviceUser = nil
        groupConversation = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func createSut() {
        sut = ServiceDetailViewController(
            serviceUser: serviceUser,
            actionType: .removeService(groupConversation),
            userSession: UserSessionMock(mockUser: mockSelfUser)
        )
    }

    func testForTeamMemberWrappedInNavigationController() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = true
            createSut()
            let navigationController = sut.wrapInNavigationController()
            snapshotHelper.verify(matching: navigationController)
        }
    }

    func testForTeamPartner() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = false
            createSut()
            snapshotHelper.verify(matching: sut)
        }
    }
}
