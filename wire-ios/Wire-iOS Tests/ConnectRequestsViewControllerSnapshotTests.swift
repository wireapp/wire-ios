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

import WireDataModel
import WireTestingPackage
import XCTest

@testable import Wire

final class ConnectRequestsViewControllerSnapshotTests: XCTestCase {

    private var sut: ConnectRequestsViewController!
    private var mockConnectionRequest: SwiftMockConversation!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        let mockUser = MockUserType.createSelfUser(name: "Bruno")
        mockUser.zmAccentColor = .amber
        mockUser.handle = "bruno"

        mockConnectionRequest = SwiftMockConversation()
        mockConnectionRequest.connectedUserType = mockUser

        userSession = UserSessionMock(mockUser: mockUser)

        sut = ConnectRequestsViewController(userSession: userSession)

        sut.loadViewIfNeeded()

        sut.connectionRequests = [mockConnectionRequest]
        sut.reload()

        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        userSession = nil
        mockConnectionRequest = nil

        super.tearDown()
    }

    func testForOneRequest() {
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    func testForTwoRequests() {
        let otherUser = MockUserType.createConnectedUser(name: "Bill")
        otherUser.zmAccentColor = .amber
        otherUser.handle = "bill"

        let secondConnectionRequest = SwiftMockConversation()
        secondConnectionRequest.connectedUserType = otherUser

        sut.connectionRequests = [secondConnectionRequest, mockConnectionRequest]
        sut.reload(animated: false)

        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }
}
