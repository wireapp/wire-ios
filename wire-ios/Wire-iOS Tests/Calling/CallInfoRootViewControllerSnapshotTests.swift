// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import SnapshotTesting
import XCTest
import WireUtilities
@testable import Wire

final class CallInfoViewControllerSnapshotTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        CallingConfiguration.config = .largeConferenceCalls
        UserDefaults.applicationGroup.set(true, forKey: DeveloperFlag.deprecatedCallingUI.rawValue)
    }

    override func tearDown() {
        CallingConfiguration.resetDefaultConfig()
        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneIncomingAudioRinging() {
        // given
        let otherUser = MockUserType.createConnectedUser(name: "Bruno")
        let selfUser = MockUserType.createSelfUser(name: "Alice")
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: SwiftMockLoader.mockUsers())

        // when
        let sut = CallInfoViewController(configuration: fixture.oneToOneIncomingAudioRinging, selfUser: selfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
}
