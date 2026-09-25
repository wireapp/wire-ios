//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import AVKit
import PassKit
import XCTest

@testable import Wire

final class MessagePresenterTests: XCTestCase {

    var sut: MessagePresenter!
    var mediaPlaybackManager: MediaPlaybackManager!
    var originalRootViewController: UIViewController!
    var userSession: UserSessionMock!

    private var rootViewController: UIViewController! {
        get { (UIApplication.shared.delegate as? AppDelegate)?.mainWindow?.rootViewController }
        set { (UIApplication.shared.delegate as? AppDelegate)?.mainWindow?.rootViewController = newValue }
    }

    override func setUp() {
        super.setUp()
        userSession = UserSessionMock()
        mediaPlaybackManager = MediaPlaybackManager(name: nil, userSession: userSession)
        sut = MessagePresenter(userSession: userSession, mediaPlaybackManager: mediaPlaybackManager)
        UIView.setAnimationsEnabled(false)

        if originalRootViewController == nil {
            originalRootViewController = rootViewController
        }
    }

    override func tearDown() {
        sut = nil
        mediaPlaybackManager = nil
        sut = nil
        super.tearDown()
        UIView.setAnimationsEnabled(true)
        rootViewController = originalRootViewController
    }

    // MARK: - Video

    func testThatAVPlayerViewControllerIsPresentedWhenOpeningAVideoFile() {
        // GIVEN
        let message = MockMessageFactory.videoMessage()
        let fileURL = Bundle(for: MockAudioRecorder.self).url(forResource: "video", withExtension: "mp4")
        message.backingFileMessageData?.fileURL = fileURL

        let targetViewController = UIViewController()
        rootViewController = targetViewController
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

    func testThatMultiplePendingDownloadsAreObservedIndependently() {
        // GIVEN
        let messageA: MockMessage = MockMessageFactory.videoMessage()
        let messageB: MockMessage = MockMessageFactory.videoMessage()
        messageA.backingFileMessageData.fileURL = nil
        messageB.backingFileMessageData.fileURL = nil

        var onChangedByNonce: [UUID: (ZMConversationMessage) -> Void] = [:]
        sut.makeFileDownloadObserver = { message, _, onChanged in
            onChangedByNonce[message.nonce!] = onChanged
            return FakeFileDownloadObserver()
        }

        let targetViewController = UIViewController()
        rootViewController = targetViewController
        sut.targetViewController = targetViewController
        _ = targetViewController.view

        // WHEN tapping both videos before either download completes
        sut.openFileMessage(messageA, targetView: UIView())
        sut.openFileMessage(messageB, targetView: UIView())

        // THEN both are tracked as independent, still-pending downloads
        XCTAssertEqual(sut.fileAvailabilityObservers.count, 2)
        XCTAssertNotNil(onChangedByNonce[messageA.nonce!])
        XCTAssertNotNil(onChangedByNonce[messageB.nonce!])

        // WHEN messageB's download finishes first
        let fileURL = Bundle(for: MockAudioRecorder.self).url(forResource: "video", withExtension: "mp4")
        messageB.backingFileMessageData.fileURL = fileURL
        messageB.backingFileMessageData.downloadState = .downloaded
        onChangedByNonce[messageB.nonce!]?(messageB)

        // THEN messageB opens, and messageA's pending observer is unaffected
        XCTAssert(targetViewController.presentedViewController is AVPlayerViewController)
        XCTAssertEqual(sut.fileAvailabilityObservers.count, 1)
        XCTAssertNotNil(sut.fileAvailabilityObservers[messageA.nonce!])

        targetViewController.presentedViewController?.beginAppearanceTransition(false, animated: false)
        targetViewController.presentedViewController?.endAppearanceTransition()

        // WHEN messageA's download finishes afterwards
        messageA.backingFileMessageData.fileURL = fileURL
        messageA.backingFileMessageData.downloadState = .downloaded
        onChangedByNonce[messageA.nonce!]?(messageA)

        // THEN messageA also opens
        XCTAssert(targetViewController.presentedViewController is AVPlayerViewController)
        XCTAssertTrue(sut.fileAvailabilityObservers.isEmpty)
    }

    func testThatObserverIsRemovedWhenDownloadConcludesWithoutSuccess() {
        // GIVEN
        let message: MockMessage = MockMessageFactory.videoMessage()
        message.backingFileMessageData.fileURL = nil

        var onChanged: ((ZMConversationMessage) -> Void)?
        sut.makeFileDownloadObserver = { _, _, changed in
            onChanged = changed
            return FakeFileDownloadObserver()
        }

        let targetViewController = UIViewController()
        rootViewController = targetViewController
        sut.targetViewController = targetViewController
        _ = targetViewController.view

        // WHEN
        sut.openFileMessage(message, targetView: UIView())
        XCTAssertEqual(sut.fileAvailabilityObservers.count, 1)

        // WHEN the download concludes without ever becoming available (failure/cancellation)
        message.backingFileMessageData.downloadState = .remote
        onChanged?(message)

        // THEN the observer is cleaned up and no player is presented
        XCTAssertTrue(sut.fileAvailabilityObservers.isEmpty)
        XCTAssertNil(targetViewController.presentedViewController)
    }

    // MARK: - Pass

    func testThatMakePassesViewControllerThrowsErrorForInvalidFileURL() async throws {
        // GIVEN
        let fileURL = try XCTUnwrap(URL(string: "https://apple.com"))

        // WHEN && THEN
        do {
            _ = try await sut.makePassesViewController(fileURL: fileURL)
            XCTFail("expected to throw an error!")
        } catch {
            // success
        }
    }

    func testThatCreateAddPassesViewControllerReturnsAViewControllerForPassFileMessage() async throws {
        // GIVEN
        let message = MockMessageFactory.passFileTransferMessage()
        let fileURL = try XCTUnwrap(message.fileMessageData?.temporaryURLToDecryptedFile())

        // WHEN
        _ = try await sut.makePassesViewController(fileURL: fileURL)

        // THEN
        // expected not to throw an error!
    }
}

/// Test double standing in for `MessageKeyPathObserver`, letting tests trigger the
/// "download state changed" callback directly instead of going through a real `ZMUserSession`.
private final class FakeFileDownloadObserver: FileDownloadObserving {}
