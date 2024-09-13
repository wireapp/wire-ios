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

import avs
import Foundation
import XCTest
@testable import Wire

final class MockAudioRecordKeyboardDelegate: AudioRecordViewControllerDelegate {
    var didCancelHitCount = 0
    func audioRecordViewControllerDidCancel(_: AudioRecordBaseViewController) {
        didCancelHitCount += 1
    }

    var didStartRecordingHitCount = 0
    func audioRecordViewControllerDidStartRecording(_: AudioRecordBaseViewController) {
        didStartRecordingHitCount += 1
    }

    var wantsToSendAudioHitCount = 0
    func audioRecordViewControllerWantsToSendAudio(
        _ audioRecordViewController: AudioRecordBaseViewController,
        recordingURL: URL,
        duration: TimeInterval,
        filter: AVSAudioEffectType
    ) {
        wantsToSendAudioHitCount += 1
    }
}

final class MockAudioRecorder: AudioRecorderType {
    var format: AudioRecorderFormat = .wav
    var state: AudioRecorderState = .initializing
    var fileURL: URL? = Bundle(for: MockAudioRecorder.self).url(forResource: "audio_sample", withExtension: "m4a")
    var maxRecordingDuration: TimeInterval? = 25 * 60
    var maxFileSize: UInt64? = 25 * 1024 * 1024 - 32
    var currentDuration: TimeInterval = 0.0
    var recordTimerCallback: ((TimeInterval) -> Void)?
    var recordLevelCallBack: ((RecordingLevel) -> Void)?
    var playingStateCallback: ((PlayingState) -> Void)?
    var recordStartedCallback: (() -> Void)?
    var recordEndedCallback: ((Result<Void, Error>) -> Void)?

    var startRecordingHitCount = 0
    func startRecording(_ completion: @escaping (Bool) -> Void) {
        state = .recording(start: 0)
        startRecordingHitCount += 1
        completion(true)
    }

    var stopRecordingHitCount = 0
    @discardableResult
    func stopRecording() -> Bool {
        state = .stopped
        stopRecordingHitCount += 1
        return true
    }

    var deleteRecordingHitCount = 0
    func deleteRecording() {
        deleteRecordingHitCount += 1
    }

    var playRecordingHitCount = 0
    func playRecording() {
        playRecordingHitCount += 1
    }

    var stopPlayingHitCount = 0
    func stopPlaying() {
        stopPlayingHitCount += 1
    }

    func levelForCurrentState() -> RecordingLevel {
        0
    }

    func durationForCurrentState() -> TimeInterval? {
        0
    }

    func alertForRecording(error: RecordingError) -> UIAlertController? {
        nil
    }
}

final class AudioRecordKeyboardViewControllerTests: XCTestCase {
    var sut: AudioRecordKeyboardViewController!
    var audioRecorder: MockAudioRecorder!
    var mockDelegate: MockAudioRecordKeyboardDelegate!
    var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()
        userSession = UserSessionMock()
        audioRecorder = MockAudioRecorder()
        mockDelegate = MockAudioRecordKeyboardDelegate()
        sut = AudioRecordKeyboardViewController(audioRecorder: audioRecorder, userSession: userSession)
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut = nil
        audioRecorder = nil
        mockDelegate = nil
        userSession = nil
        super.tearDown()
    }

    func testThatItStartsRecordingWhenClickingRecordButton() {
        // when
        sut.recordButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(audioRecorder.stopRecordingHitCount, 0)
        XCTAssertEqual(audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItStartsRecordingWhenClickingRecordArea() {
        // when
        sut.recordButtonPressed(self)

        // then
        XCTAssertEqual(audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(audioRecorder.stopRecordingHitCount, 0)
        XCTAssertEqual(audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItStopsRecordingWhenClickingStopButton() {
        // when
        sut.recordButtonPressed(self)

        // and when
        sut.stopRecordButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(audioRecorder.startRecordingHitCount, 1)
        XCTAssertEqual(audioRecorder.stopRecordingHitCount, 1)
        XCTAssertEqual(audioRecorder.deleteRecordingHitCount, 0)
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.recording)
        XCTAssertEqual(mockDelegate.didStartRecordingHitCount, 1)
    }

    func testThatItSwitchesToEffectsScreenAfterRecord() {
        // when
        sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        audioRecorder.recordEndedCallback!(.success(()))

        // then
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.effects)
    }

    func testThatItSwitchesToRecordingAfterRecordDiscarded() {
        // when
        sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        audioRecorder.recordEndedCallback!(.success(()))
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.effects)

        // and when
        sut.redoButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.ready)
        XCTAssertEqual(mockDelegate.didStartRecordingHitCount, 1)
        XCTAssertEqual(audioRecorder.deleteRecordingHitCount, 1)
    }

    func testThatItCallsErrorDelegateCallback() {
        // when
        sut.recordButton.sendActions(for: .touchUpInside)

        // and when
        audioRecorder.recordEndedCallback!(.success(()))
        XCTAssertEqual(sut.state, AudioRecordKeyboardViewController.State.effects)

        // and when
        sut.cancelButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockDelegate.didStartRecordingHitCount, 1)
        XCTAssertEqual(mockDelegate.didCancelHitCount, 1)
    }
}
