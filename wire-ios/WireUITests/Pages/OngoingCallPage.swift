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

import Foundation
import WireLocators
import XCTest

class OngoingCallPage: PageModel {

    override var pageMainElement: XCUIElement {
        timeLabel
    }

    var timeLabel: XCUIElement {
        app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
    }

    var endCallButton: XCUIElement {
        app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue]
    }

    var microphoneButton: XCUIElement {
        app.buttons[Locators.OngoingCallPage.microphoneButton.rawValue]
    }

    var cameraButton: XCUIElement {
        app.buttons[Locators.OngoingCallPage.cameraButton.rawValue]
    }

    var speakerButton: XCUIElement {
        app.buttons[Locators.OngoingCallPage.speakerButton.rawValue]
    }

    var minimizeCallButton: XCUIElement {
        app.buttons[Locators.OngoingCallPage.minimizeCall.rawValue]
    }

    var turnOnCameraButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Turn on camera")).firstMatch
    }

    var turnOffCameraButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Turn off camera")).firstMatch
    }

    var flipCameraButton: XCUIElement {
        app.buttons["CallFlipCameraButton"].firstMatch
    }

    func participant(named name: String) -> XCUIElement {
        app.buttons[Locators.OngoingCallPage.participantIdentifier(name)]
    }

    func videoView(for participantName: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(
                format: """
                (identifier BEGINSWITH %@ OR label CONTAINS[c] %@) AND
                (identifier CONTAINS[c] %@ OR label CONTAINS[c] %@) AND
                (identifier CONTAINS[c] %@ OR identifier CONTAINS[c] %@ OR label CONTAINS[c] %@)
                """,
                "videoView",
                participantName,
                participantName,
                participantName,
                "minimized",
                "maximized",
                "Camera on"
            )
        ).firstMatch
    }

    func screenSharingView(for participantName: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(
                format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
                participantName,
                Locators.OngoingCallPage.sharesScreenDescription.rawValue
            )
        ).firstMatch
    }

    @discardableResult
    func isOtherParticipantVideoTileVisible(
        for participantName: String,
        timeout: TimeInterval = 20
    ) -> OngoingCallPage {
        let tile = videoView(for: participantName)
        XCTAssertTrue(
            tile.waitForExistence(timeout: timeout),
            "Remote video is not visible for \(participantName)"
        )

        XCTAssertTrue(
            tile.identifier.localizedCaseInsensitiveContains(participantName) ||
                tile.label.localizedCaseInsensitiveContains(participantName),
            "Remote video tile did not match participant \(participantName). Identifier: \(tile.identifier). Label: \(tile.label)"
        )
        return self
    }

    @discardableResult
    func isOtherParticipantScreenSharingVisible(
        for participantName: String,
        timeout: TimeInterval = 15
    ) -> OngoingCallPage {
        let tile = screenSharingView(for: participantName)
        XCTAssertTrue(
            tile.waitForExistence(timeout: timeout),
            "screen share is not visible for \(participantName)"
        )
        return self
    }

    private func tapEndCallButton() {
        endCallButton.tapAndWait()
    }

    @discardableResult
    func toggleMicrophone() -> OngoingCallPage {
        microphoneButton.tapAndWait()
        return self
    }

    @discardableResult
    func toggleCamera() -> OngoingCallPage {
        cameraButton.tapAndWait()
        app.dismissAllowIfPresent()
        return self
    }

    @discardableResult
    func toggleSpeaker() -> OngoingCallPage {
        speakerButton.tapAndWait()
        return self
    }

    func endOngoingCall() throws -> ConversationsPage {
        tapEndCallButton()
        return try ConversationsPage()
    }

    func hangUpOngoingCall() throws -> ActiveConversationPage {
        tapEndCallButton()
        return try ActiveConversationPage()
    }

    func minimizeCallUI() throws -> ActiveConversationPage {
        minimizeCallButton.tap()
        return try ActiveConversationPage()
    }

    @discardableResult
    func verifyMicrophoneToggle() -> OngoingCallPage {
        toggleMicrophone()
        XCTAssertEqual(
            microphoneButton.label,
            "Turn on microphone",
            "Microphone should be OFF after tapping the microphone button"
        )

        toggleMicrophone()
        XCTAssertEqual(
            microphoneButton.label,
            "Turn off microphone",
            "Microphone should be ON after tapping the microphone button again"
        )
        return self
    }

    @discardableResult
    func verifyCameraToggle() -> OngoingCallPage {
        toggleCamera()
        XCTAssertEqual(
            cameraButton.label,
            "Turn off camera",
            "Camera should be ON after tapping the camera button"
        )

        toggleCamera()
        XCTAssertEqual(
            cameraButton.label,
            "Turn on camera",
            "Camera should be OFF after tapping the camera button again"
        )
        return self
    }

    @discardableResult
    func verifySpeakerToggle() -> OngoingCallPage {
        toggleSpeaker()
        XCTAssertEqual(
            speakerButton.label,
            "Turn off speaker",
            "Speaker should be ON after tapping the speaker button"
        )

        toggleSpeaker()
        XCTAssertEqual(
            speakerButton.label,
            "Turn on speaker",
            "Speaker should be OFF after tapping the speaker button again"
        )
        return self
    }

    @discardableResult
    func turnOnVideo() throws -> OngoingCallPage {
        if turnOnCameraButton.waitAndTap(timeout: 5) {
            app.dismissAllowIfPresent(timeout: 2)
            return self
        }

        XCTAssertTrue(cameraButton.waitAndTap(timeout: 5), "Camera button is not visible")
        app.dismissAllowIfPresent(timeout: 2)
        return self
    }

    @discardableResult
    func flipCamera() throws -> OngoingCallPage {
        XCTAssertTrue(flipCameraButton.waitAndTap(timeout: 5), "Flip camera button is not visible")
        return self
    }

    @discardableResult
    func turnOffVideo() throws -> OngoingCallPage {
        if turnOffCameraButton.waitAndTap(timeout: 5) {
            return self
        }

        XCTAssertTrue(cameraButton.waitAndTap(timeout: 5), "Camera button is not visible")
        return self
    }
}
