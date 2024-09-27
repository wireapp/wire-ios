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

import WireDataModelSupport
import XCTest
@testable import Wire

final class ZClientViewControllerTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        coreDataFixture = .init()
        imageTransformer = .init()
        userSession = UserSessionMock(mockUser: .createSelfUser(name: "Bob"))
        userSession.coreDataStack = coreDataFixture.coreDataStack
        sut = ZClientViewController(
            account: Account.mockAccount(imageData: mockImageData),
            userSession: userSession
        )
    }

    override func tearDown() {
        sut = nil
        userSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func testThatCustomPasscodeWillBeDeleted_AfterUserNotifiedOfDisabledApplock() {
        // When
        sut.appLockChangeWarningViewControllerDidDismiss()

        // Then
        XCTAssertEqual(userSession.deleteAppLockPasscodeCalls, 1)
    }

    // MARK: Private

    private var coreDataFixture: CoreDataFixture!
    private var imageTransformer: MockImageTransformer!
    private var sut: ZClientViewController!
    private var userSession: UserSessionMock!
}
