// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
import XCTest
@testable import Wire

final class AudioRecordKeyboardViewControllerTests: XCTestCase {
    var sut: AudioRecordKeyboardViewController!
    var audioRecorder: MockAudioRecorder!
    var mockDelegate: MockAudioRecordKeyboardDelegate!

    override func setUp() {
        super.setUp()
        self.audioRecorder = MockAudioRecorder()
        self.mockDelegate = MockAudioRecordKeyboardDelegate()
        self.sut = AudioRecordKeyboardViewController(audioRecorder: self.audioRecorder)
        self.sut.delegate = self.mockDelegate
    }

    override func tearDown() {
        self.sut = nil
        self.audioRecorder = nil
        self.mockDelegate = nil
        super.tearDown()
    }

    func testThatItStartsRecordingWhenClickingRecordButton() {
        // when
        self.sut.recordButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(self.audioRecorder.stopRecordingHitCount, 0)
        XCTAssertEqual(self.audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(self.mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItStartsRecordingWhenClickingRecordArea() {
        // when
        self.sut.recordButtonPressed(self)

        // then
        XCTAssertEqual(self.audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(self.audioRecorder.stopRecordingHitCount, 0)
        XCTAssertEqual(self.audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(self.mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItStopsRecordingWhenClickingStopButton() {
        // when
        self.sut.recordButtonPressed(self)

        // and when
        self.sut.stopRecordButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(self.audioRecorder.stopRecordingHitCount, 1)
        XCTAssertEqual(self.audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(self.mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItSwitchesToEffectsScreenAfterRecord() {
        // when
        self.sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        self.audioRecorder.recordEndedCallback!(.success)

        // then
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.effects)
    }

    func testThatItSwitchesToRecordingAfterRecordDiscarded() {
        // when
        self.sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        self.audioRecorder.recordEndedCallback!(.success)
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.effects)

        // and when
        self.sut.redoButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.ready)
        XCTAssertEqual(self.mockDelegate.didStartRecordingHitCount, 1)
        XCTAssertEqual(self.audioRecorder.deleteRecordingHitCount, 1)
    }

    func testThatItCallsErrorDelegateCallback() {
        // when
        self.sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        self.audioRecorder.recordEndedCallback!(.success)
        XCTAssertEqual(self.sut.state, AudioRecordKeyboardViewController.State.effects)

        // and when
        self.sut.cancelButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.mockDelegate.didStartRecordingHitCount, 1)
        XCTAssertEqual(self.mockDelegate.didCancelHitCount, 1)
    }

}
