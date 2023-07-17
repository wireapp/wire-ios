//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
@testable import Wire
import XCTest

final class UserConnectionViewTests: XCTestCase {

    func sutForUser(_ mockUser: MockUserType = SwiftMockLoader.mockUsers().first!, isFederated: Bool = false) -> UserConnectionView {
        mockUser.isPendingApprovalByOtherUser = true
        mockUser.isPendingApprovalBySelfUser = false
        mockUser.isConnected = false
        mockUser.isFederated = isFederated
        mockUser.domain = "wire.com"

        let connectionView = UserConnectionView(user: mockUser)
        connectionView.layoutForTest()

        return connectionView
    }

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    func testWithUserName() {
        let sut = sutForUser()
        sut.layoutForTest()
        verify(matching: sut)
    }

    func testWithUserName_Federated() {
        let sut = sutForUser(isFederated: true)
        sut.layoutForTest()
        verify(matching: sut)
    }

    func testWithoutUserName() {
        // The last mock user does not have a handle
        let user = SwiftMockLoader.mockUsers().last!
        let sut = sutForUser(user)
        sut.layoutForTest()
        verify(matching: sut)
    }

}
