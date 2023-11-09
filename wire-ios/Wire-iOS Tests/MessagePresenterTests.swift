//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import PassKit
import AVKit

final class MessagePresenterTests: XCTestCase {

    var sut: MessagePresenter!
    var mediaPlaybackManager: MediaPlaybackManager!
    var originalRootViewConttoller: UIViewController!

    override func setUp() {
        super.setUp()
        mediaPlaybackManager = MediaPlaybackManager(name: nil)
        sut = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)
        UIView.setAnimationsEnabled(false)

        if originalRootViewConttoller == nil {
            originalRootViewConttoller = UIApplication.shared.firstKeyWindow?.rootViewController
        }
    }

    override func tearDown() {
        sut = nil
        mediaPlaybackManager = nil
        super.tearDown()
        UIView.setAnimationsEnabled(true)
        UIApplication.shared.firstKeyWindow?.rootViewController = originalRootViewConttoller
    }

    // MARK: - Video
    func testThatAVPlayerViewControllerIsPresentedWhenOpeningAVideoFile() {
        // GIVEN
        let message = MockMessageFactory.videoMessage()
        let fileURL = Bundle(for: MockAudioRecorder.self).url(forResource: "video", withExtension: "mp4")
        message.backingFileMessageData?.fileURL = fileURL

        let targetViewController = UIViewController()
        UIApplication.shared.firstKeyWindow?.rootViewController = targetViewController
        sut.targetViewController = targetViewController
        _ = targetViewController.view

        // WHEN
        sut.openFileMessage(message, targetView: UIView())

        // THEN
        let playerViewController = targetViewController.presentedViewController!
        XCTAssert(playerViewController is AVPlayerViewController)
        XCTAssertNotNil(sut.videoPlayerObserver)

        // Dismiss
        playerViewController.beginAppearanceTransition(false, animated: false)
        playerViewController.endAppearanceTransition()

        // THEN
        XCTAssertNil(sut.videoPlayerObserver)
    }

    // MARK: - Pass

    func testThatCreateAddPassesViewControllerReturnsNilForFileMessage() {
        // GIVEN
        let message = MockMessageFactory.fileTransferMessage()
        let expectation = self.expectation(description: "Load pass data and create addPassesViewController")

        // WHEN
        var addPassesViewControllerResult: PKAddPassesViewController?
        sut.loadPassDataAndCreateAddPassesViewController(fileMessageData: message.fileMessageData!) { addPassesViewController in
            addPassesViewControllerResult = addPassesViewController
            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(addPassesViewControllerResult)
    }


    func testThatCreateAddPassesViewControllerReturnsAViewControllerForPassFileMessage() {
        // GIVEN
        let message = MockMessageFactory.passFileTransferMessage()
        let expectation = self.expectation(description: "Should receive a PKAddPassesViewController")

        // WHEN
        var addPassesViewControllerResult: PKAddPassesViewController?
        sut.loadPassDataAndCreateAddPassesViewController(fileMessageData: message.fileMessageData!) { addPassesViewController in
            addPassesViewControllerResult = addPassesViewController
            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithError: \(error)")
            }

            XCTAssertNotNil(addPassesViewControllerResult)
        }
    }

}
