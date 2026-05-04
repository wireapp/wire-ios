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

import XCTest
@testable import Wire

extension MockMessage: AudioTrack {

    var title: String? {
        .none
    }

    var author: String? {
        .none
    }

    var duration: TimeInterval {
        9999
    }

    var streamURL: URL? {
        .none
    }

    var previewStreamURL: URL? {
        .none
    }

    var failedToLoad: Bool {
        get {
            false
        }
        set {
            // no-op
        }
    }
}

final class AudioMessageViewTests: XCTestCase {

    var sut: AudioMessageView!
    var mediaPlaybackManager: MediaPlaybackManager!
    var userSession: UserSessionMock!
    var coreDataStack: CoreDataStack!

    override func setUp() {
        userSession = UserSessionMock()
        let url = Bundle(for: type(of: self)).url(forResource: "audio_sample", withExtension: "m4a")!

        let audioMessage = MockMessageFactory.audioMessage(config: {
            $0.backingFileMessageData?.transferState = .uploaded
            $0.backingFileMessageData?.downloadState = .downloaded
            $0.backingFileMessageData.fileURL = url
        })

        mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia", userSession: userSession)
        sut = AudioMessageView(mediaPlaybackManager: mediaPlaybackManager)

        sut.audioTrackPlayer?.load(audioMessage, sourceMessage: audioMessage)
        sut.configure(for: audioMessage, isInitial: true)

        coreDataStack = CoreDataStack(
            account: Account(userName: "", userIdentifier: UUID()),
            applicationContainer: URL.documentsDirectory,
            inMemoryStore: true,
            localDomain: "wire.com",
            isFederationEnabled: false
        )
    }

    override func tearDown() {
        sut = nil
        userSession = nil
        mediaPlaybackManager = nil
        coreDataStack = nil
    }

    func testThatAudioMessageIsResumedAfterIncomingCallIsTerminated() {
        // GIVEN & WHEN

        // play
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)

        // THEN
        let incomingState = CallState.incoming(isVideo: false, shouldRing: true, degraded: false)
        sut.callCenterDidChange(
            callState: incomingState,
            conversation: ZMConversation(context: coreDataStack.viewContext),
            caller: ZMUser(context: coreDataStack.viewContext),
            timestamp: nil,
            previousCallState: nil
        )

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        sut.callCenterDidChange(
            callState: .terminating(reason: WireSyncEngine.CallClosedReason.normal),
            conversation: ZMConversation(context: coreDataStack.viewContext),
            caller: ZMUser(context: coreDataStack.viewContext),
            timestamp: nil,
            previousCallState: incomingState
        )

        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)
    }

    func testThatAudioMessageIsNotResumedIfItIsPausedAfterIncomingCallIsTerminated() {
        // GIVEN & WHEN

        // play
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)

        // pause
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        // THEN
        let incomingState = CallState.incoming(isVideo: false, shouldRing: true, degraded: false)
        sut.callCenterDidChange(
            callState: incomingState,
            conversation: ZMConversation(context: coreDataStack.viewContext),
            caller: ZMUser(context: coreDataStack.viewContext),
            timestamp: nil,
            previousCallState: nil
        )

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        sut.callCenterDidChange(
            callState: .terminating(reason: WireSyncEngine.CallClosedReason.normal),
            conversation: ZMConversation(context: coreDataStack.viewContext),
            caller: ZMUser(context: coreDataStack.viewContext),
            timestamp: nil,
            previousCallState: incomingState
        )

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)
    }
}
