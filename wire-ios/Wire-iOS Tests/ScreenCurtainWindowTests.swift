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

final class ScreenCurtainWindowTests: XCTestCase {

    var sut: ScreenCurtainWindow!
    var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper_!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        sut = ScreenCurtainWindow()
        userSession = UserSessionMock()
        sut.userSession = userSession
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Showing

    func test_ItIsVisible_IfNeeded() {
        // Given
        userSession.requiresScreenCurtain = true

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertFalse(sut.isHidden)
    }

    func test_ItIsHidden_IfNeeded() {
        // Given
        userSession.requiresScreenCurtain = false

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    func test_ItIsHidden_IfNoDelegate() {
        // Given
        sut.userSession = nil

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    // MARK: - Hiding

    func test_ItIsHidden_WhenApplicationBecomesActive() {
        // Given
        sut.isHidden = false

        // When
        sut.applicationDidBecomeActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    // MARK: - UI

    func test_UI() {
        // Given
        sut.isHidden = false

        // Then
        snapshotHelper.verify(matching: sut.rootViewController!)
    }
}
