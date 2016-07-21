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


@testable import Wire
import Classy

@objc class AudioButtonOverlayTests: ZMSnapshotTestCase {
    
    var sut: AudioButtonOverlay!
    var buttonTapHistory: [AudioButtonOverlay.AudioButtonOverlayButtonType]!
    
    override func setUp() {
        super.setUp()
        buttonTapHistory = []
        sut = AudioButtonOverlay()
        sut.buttonHandler = { self.buttonTapHistory.append($0) }
        CASStyler.defaultStyler().styleItem(sut)
    }
    
    func testThatItRendersTheButtonOverlayCorrectInitially_Recording() {
        sut.setOverlayState(.Default)
        verify(view: sut)
    }
    
    func testThatItRendersTheButtonOverlayCorrectInitially_FinishedRecording() {
        sut.recordingState = .FinishedRecording
        sut.setOverlayState(.Default)
        verify(view: sut)
    }
    
    func testThatItRendersTheButtonOverlayCorrectInitially_FinishedRecording_PlayingAudio() {
        sut.recordingState = .FinishedRecording
        sut.playingState = .Playing
        sut.setOverlayState(.Default)
        verify(view: sut)
    }
        
    func testThatItChangesItsSize_Expanded() {
        sut.setOverlayState(.Expanded(0))
        verify(view: sut)
    }
    
    func testThatItChangesItsSize_Expanded_Half() {
        sut.setOverlayState(.Expanded(0.5))
        verify(view: sut)
    }
    
    func testThatItChangesItsSize_Expanded_Full() {
        sut.setOverlayState(.Expanded(1))
        verify(view: sut)
    }
    
    func testThatItCallsTheButtonHandlerWithTheCorrectButtonType() {
        sut.playButton.sendActionsForControlEvents(.TouchUpInside)
        XCTAssertEqual(buttonTapHistory, [.Play])
        
        sut.sendButton.sendActionsForControlEvents(.TouchUpInside)
        XCTAssertEqual(buttonTapHistory, [.Play, .Send])
    }
    
}
