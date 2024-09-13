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

final class AudioRecordKeyboardViewControllerSnapshotTests: XCTestCase {
    // MARK: - Properties

    var sut: AudioRecordKeyboardViewController!
    var mockAudioRecorder: MockAudioRecorder!
    var mockUserSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockUserSession = UserSessionMock()
        mockAudioRecorder = MockAudioRecorder()
        sut = AudioRecordKeyboardViewController(
            audioRecorder: mockAudioRecorder,
            userSession: mockUserSession
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockUserSession = nil
        mockAudioRecorder = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatSoundEffectIcon_IsPartOTheTipLabel() {
        sut.view.translatesAutoresizingMaskIntoConstraints = false
        sut.view.heightAnchor.constraint(equalToConstant: 200).isActive = true

        verifyInAllPhoneWidths(matching: sut.view)
    }
}
