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
import XCTest

final class ZMSearchUserTests_ProfileImages: ZMBaseManagedObjectTest {
    // MARK: Internal

    func testThatItReturnsPreviewsProfileImageIfItWasPreviouslyUpdated() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = makeSearchUser(name: "John")

        // when
        searchUser.updateImageData(for: .preview, imageData: imageData)

        // then
        XCTAssertEqual(searchUser.previewImageData, imageData)
    }

    func testThatItReturnsCompleteProfileImageIfItWasPreviouslyUpdated() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = makeSearchUser(name: "John")

        // when
        searchUser.updateImageData(for: .complete, imageData: imageData)

        // then
        XCTAssertEqual(searchUser.completeImageData, imageData)
    }

    func testThatItReturnsPreviewsProfileImageFromAssociatedUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .preview)
        uiMOC.saveOrRollback()

        // when
        let searchUser = makeSearchUser(user: user)

        // then
        XCTAssertEqual(searchUser.previewImageData, imageData)
    }

    func testThatItReturnsPreviewsCompleteImageFromAssociatedUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.completeProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .complete)
        uiMOC.saveOrRollback()

        // when
        let searchUser = makeSearchUser(user: user)

        // then
        XCTAssertEqual(searchUser.completeImageData, imageData)
    }

    func testThatItReturnsPreviewImageProfileCacheKey() {
        // given
        let searchUser = makeSearchUser(name: "John")

        // then
        XCTAssertNotNil(searchUser.smallProfileImageCacheKey)
    }

    func testThatItReturnsCompleteImageProfileCacheKey() {
        // given
        let searchUser = makeSearchUser(name: "John")

        // then
        XCTAssertNotNil(searchUser.mediumProfileImageCacheKey)
    }

    func testThatItPreviewAndCompleteImageProfileCacheKeyIsDifferent() {
        // given
        let searchUser = makeSearchUser(name: "John")

        // then
        XCTAssertNotEqual(searchUser.smallProfileImageCacheKey, searchUser.mediumProfileImageCacheKey)
    }

    func testThatItReturnsPreviewImageProfileCacheKeyFromUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .preview)
        uiMOC.saveOrRollback()

        // given
        let searchUser = makeSearchUser(user: user)

        // then
        XCTAssertNotNil(searchUser.smallProfileImageCacheKey)
        XCTAssertEqual(user.smallProfileImageCacheKey, searchUser.smallProfileImageCacheKey)
    }

    func testThatItReturnsCompleteImageProfileCacheKeyFromUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.completeProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .complete)
        uiMOC.saveOrRollback()

        // given
        let searchUser = makeSearchUser(user: user)

        // then
        XCTAssertNotNil(searchUser.mediumProfileImageCacheKey)
        XCTAssertEqual(user.mediumProfileImageCacheKey, searchUser.mediumProfileImageCacheKey)
    }

    func testThatItCanFetchPreviewProfileImageOnAQueue() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = makeSearchUser(name: "John")

        // when
        searchUser.updateImageData(for: .preview, imageData: imageData)

        // then
        let imageDataArrived = customExpectation(description: "completion handler called")
        searchUser.imageData(for: .preview, queue: .global()) { imageDataResult in
            XCTAssertEqual(imageData, imageDataResult)
            imageDataArrived.fulfill()
        }
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCanFetchCompleteProfileImageOnAQueue() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = makeSearchUser(name: "John")

        // when
        searchUser.updateImageData(for: .complete, imageData: imageData)

        // then
        let imageDataArrived = customExpectation(description: "completion handler called")
        searchUser.imageData(for: .complete, queue: .global()) { imageDataResult in
            XCTAssertEqual(imageData, imageDataResult)
            imageDataArrived.fulfill()
        }
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Private

    // MARK: - Helpers

    private func makeSearchUser(
        name: String,
        user: ZMUser? = nil
    ) -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            name: name,
            handle: name.lowercased(),
            accentColor: .amber,
            remoteIdentifier: UUID(),
            user: user,
            searchUsersCache: nil
        )
    }

    private func makeSearchUser(
        user: ZMUser
    ) -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            user: user,
            searchUsersCache: nil
        )
    }
}
