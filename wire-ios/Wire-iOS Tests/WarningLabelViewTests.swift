//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class WarningLabelViewTests: XCTestCase {
    var sut: WarningLabelView!
    
    override func setUp() {
        super.setUp()
        sut = WarningLabelView()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_WithSelfUserNoTeam() {
        // given
        let selfUser = MockUserType.createSelfUser(name: "selfUser", inTeam: nil)
        selfUser.isConnected = false
        // when
        sut.update(withUser: selfUser)
        // then
        XCTAssertTrue(sut.isHidden)
    }

    func test_WithUserNotConnectedOutsideTeam() {
        // given
        let testUser = MockUserType.createUser(name: "Test")
        testUser.isConnected = false
        // when
        sut.update(withUser: testUser)
        // then
        XCTAssertFalse(sut.isHidden)
    }

    func test_WithUserFromTeamNotConnected() {
        // given
        let testUser = MockUserType.createUser(name: "Test", inTeam: UUID())
        testUser.isConnected = false
        // when
        sut.update(withUser: testUser)
        // then
        XCTAssertTrue(sut.isHidden)
    }

    func test_WithUserConnectedOutsideTeam() {
        // given
        let testUser = MockUserType.createUser(name: "Test")
        testUser.isConnected = true
        // when
        sut.update(withUser: testUser)
        // then
        XCTAssertTrue(sut.isHidden)
    }

}
