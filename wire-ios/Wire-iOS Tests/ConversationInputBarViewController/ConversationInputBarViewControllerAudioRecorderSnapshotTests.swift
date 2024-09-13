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

import WireSyncEngineSupport
import XCTest

@testable import Wire

// MARK: - MockLongPressGestureRecognizer

final class MockLongPressGestureRecognizer: UILongPressGestureRecognizer {
    let mockState: UIGestureRecognizer.State
    var mockLocation: CGPoint?

    init(location: CGPoint?, state: UIGestureRecognizer.State) {
        self.mockLocation = location
        self.mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        mockLocation ?? super.location(in: view)
    }

    override var state: UIGestureRecognizer.State {
        get {
            mockState
        }
        set {}
    }
}

// MARK: - ConversationInputBarViewControllerAudioRecorderSnapshotTests

final class ConversationInputBarViewControllerAudioRecorderSnapshotTests: CoreDataSnapshotTestCase {
    // MARK: - Properties

    var sut: ConversationInputBarViewController!
    var mockLongPressGestureRecognizer: MockLongPressGestureRecognizer!
    var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        userSession = UserSessionMock()

        let mockSecurityClassificationProviding = MockSecurityClassificationProviding()
        mockSecurityClassificationProviding.classificationUsersConversationDomain_MockValue = .some(nil)

        sut = ConversationInputBarViewController(
            conversation: otherUserConversation,
            userSession: userSession,
            classificationProvider: mockSecurityClassificationProviding,
            networkStatusObservable: MockNetworkStatusObservable()
        )
        sut.overrideUserInterfaceStyle = .light
        sut.loadViewIfNeeded()

        mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .began)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockLongPressGestureRecognizer = nil
        userSession = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func longPressChanged() {
        let changedGestureRecognizer = MockLongPressGestureRecognizer(location: CGPoint(x: 0, y: -30), state: .changed)
        sut.audioButtonLongPressed(changedGestureRecognizer)
    }

    func longPressEnded() {
        let endedGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .ended)
        sut.audioButtonLongPressed(endedGestureRecognizer)
    }

    // MARK: - Snapshot Tests

    func testAudioRecorderTouchBegan() {
        // GIVEN & THEN
        verifyInAllPhoneWidths(
            matching: sut.view,
            configuration: { _ in
                // WHEN
                self.sut.createAudioViewController(
                    audioRecorder: MockAudioRecorder(),
                    userSession: self.userSession
                )
                self.sut.audioRecordViewController?.updateTimeLabel(1234)
                self.sut.showAudioRecordViewController(animated: false)
            }
        )
    }

    func testAudioRecorderTouchChanged() {
        // GIVEN & THEN
        verifyInAllPhoneWidths(
            matching: sut.view,
            configuration: { _ in
                // WHEN
                self.sut.createAudioViewController(
                    audioRecorder: MockAudioRecorder(),
                    userSession: self.userSession
                )
                self.sut.showAudioRecordViewController(animated: false)
                self.longPressChanged()
            }
        )
    }

    func testAudioRecorderTouchEnded() {
        // GIVEN & THEN
        verifyInAllPhoneWidths(
            matching: sut.view,
            configuration: { _ in
                // WHEN
                let audioRecorder = MockAudioRecorder()
                self.sut.createAudioViewController(
                    audioRecorder: audioRecorder,
                    userSession: self.userSession
                )
                self.sut.showAudioRecordViewController(animated: false)
                audioRecorder.state = .recording(start: 0)
                self.longPressEnded()
            }
        )
    }
}
