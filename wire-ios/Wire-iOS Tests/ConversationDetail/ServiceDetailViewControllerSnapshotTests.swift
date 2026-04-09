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

import WireData
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ServiceDetailViewControllerSnapshotTests: CoreDataSnapshotTestCase {

    private var sut: ServiceDetailViewController!
    private var bot: MockUserType!
    private var app: ZMUser!
    private var groupConversation: ZMConversation!
    private var mockSelfUser: MockUserType!
    private var mockUsersAPI: MockUsersAPI!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        snapshotHelper = SnapshotHelper()
        bot = .createBot(name: "AppUser")
        app = createApp(name: "AppUser")
        groupConversation = createGroupConversation()
        mockSelfUser = .createSelfUser(name: "Bob")
        mockUsersAPI = .init()
    }

    override func tearDown() {
        mockUsersAPI = nil
        snapshotHelper = nil
        sut = nil
        bot = nil
        groupConversation = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func createSut(user: any UserType) {
        sut = ServiceDetailViewController(
            user: user,
            actionType: .removeParticipant(groupConversation),
            userSession: UserSessionMock(mockUser: mockSelfUser),
            usersAPI: mockUsersAPI,
            completion: { _ in }
        )
    }

    func testForTeamMemberWrappedInNavigationController() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = true
            createSut(user: bot)
            let navigationController = sut.wrapInNavigationController()
            snapshotHelper.verify(matching: navigationController)
        }
    }

    func testForTeamPartner() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = false
            createSut(user: bot)
            snapshotHelper.verify(matching: sut)
        }
    }

    @MainActor
    func testDisplayingApp() async {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = true
            app.teamIdentifier = team?.remoteIdentifier
            let appInfo = WireData.AppInfo(context: team!.managedObjectContext!)
            appInfo.appDescription = "Lorem Ipsum Dolor Sit Amet"
            appInfo.category = "Some Category"
            app.appInfo = appInfo
            let membership = Member(context: groupConversation.managedObjectContext!)
            membership.user = app
            membership.team = team
            createSut(user: app)
        }
        mockUsersAPI.getUserFor_MockMethod = { _ in
            try? await Task.sleep(for: .seconds(999))
            fatalError("should never execute this")
        }
        let navigationController = sut.wrapInNavigationController()
        snapshotHelper.verify(matching: navigationController)
    }

}
