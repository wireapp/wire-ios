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

@testable import Wire

final class FullscreenImageViewControllerTests: XCTestCase {

    var sut: FullscreenImageViewController!
    var userSession: UserSessionMock!

    override func setUp() {
        userSession = UserSessionMock()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        sut = nil
        userSession = nil
        UIView.setAnimationsEnabled(true)
    }

    @MainActor
    func testThatScrollViewMinimumZoomScaleAndZoomScaleAreSet() {
        // GIVEN & WHEN
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn.jpg", userSession: userSession)
        let image: UIImage = sut.imageView!.image!
        sut.updateScrollViewZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.view.bounds.size.width / image.size.width)

        XCTAssertLessThanOrEqual(abs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), FullscreenImageViewController.kZoomScaleDelta)
    }

    @MainActor
    func testThatDoubleTapZoomToScreenFitWhenTheImageIsSmallerThanTheView() {
        // GIVEN
        // The image is 70 * 70
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn_small_size.jpg", userSession: userSession)

        let maxZoomScale = sut.scrollView.maximumZoomScale

        XCTAssertEqual(maxZoomScale, sut.view.frame.width / 70.0)

        XCTAssertLessThanOrEqual(abs(sut.scrollView.zoomScale - 1), FullscreenImageViewController.kZoomScaleDelta)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, maxZoomScale)
    }

    @MainActor
    func testThatDoubleTapZoomInTheImage() {
        // GIVEN
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn.jpg", userSession: userSession)

        XCTAssertLessThanOrEqual(abs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), FullscreenImageViewController.kZoomScaleDelta)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, 1)
    }

    @MainActor
    func testThatRotateScreenResetsZoomScaleToMinZoomScale() {
        // GIVEN
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn.jpg", userSession: userSession)

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.scrollView.zoomScale)
        let image: UIImage = sut.imageView!.image!
        XCTAssertEqual(sut.view.bounds.size.height / image.size.height, sut.scrollView.minimumZoomScale)
    }

    @MainActor
    func testThatRotateScreenReserveZoomScaleIfDoubleTapped() {
        // GIVEN
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn.jpg", userSession: userSession)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        XCTAssertEqual(1, sut.scrollView.zoomScale)

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        XCTAssertEqual(1, sut.scrollView.zoomScale)
    }

    @MainActor
    func testThatRotateScreenUpdatesMaxZoomScaleIfASmallImageIsZoomedIn() {
        // GIVEN
        sut = createFullscreenImageViewControllerForTest(imageFileName: "unsplash_matterhorn_very_small_size_40x20.jpg", userSession: userSession)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        let maxZoomScale = sut.scrollView.maximumZoomScale
        XCTAssertEqual(maxZoomScale, sut.view.frame.width / 40.0)

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        let landscapeMaxZoomScale = sut.scrollView.maximumZoomScale
        XCTAssertNotEqual(maxZoomScale, landscapeMaxZoomScale)
    }
}
