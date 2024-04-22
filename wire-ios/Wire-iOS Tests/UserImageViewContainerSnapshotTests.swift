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

import XCTest
import SnapshotTesting
@testable import Wire

final class UserImageViewContainerSnapshotTests: XCTestCase {

    // MARK: - Properties

    var sut: UserImageViewContainer!
    var mockUser: MockUserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        mockUser = SwiftMockLoader.mockUsers().first
        mockUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").imageData
        mockUser.mediumProfileImageCacheKey = "test"
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockUser = nil

        super.tearDown()
    }

    // MARK: - Helper

    func setupSut(userSession: UserSessionMock?) {
        let maxSize = CGFloat(240)

        sut = UserImageViewContainer(
            size: .big,
            maxSize: maxSize,
            yOffset: 0,
            userSession: userSession
        )
        sut.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: maxSize,
                height: maxSize
            )
        )
        sut.user = mockUser
    }

    // MARK: - Snapshot Tests

    func testForNoUserImageWithoutSession() {
        setupSut(userSession: nil)

        verify(matching: sut)
    }

    func testForWithUserImage() {
        setupSut(userSession: UserSessionMock(mockUser: mockUser))

        XCTAssertTrue(
            waitForGroupsToBeEmpty(
                [MediaAssetCache.defaultImageCache.dispatchGroup]
            )
        )
        verify(matching: sut)
    }
}
