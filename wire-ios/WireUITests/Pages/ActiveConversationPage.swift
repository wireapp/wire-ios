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

import WireLocators
import XCTest

class ActiveConversationPage: PageModel {

    override var pageMainElement: XCUIElement {
        conversationTitleButton
    }

    var videoCallButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCallBarButton.rawValue].firstMatch
    }

    var inputMessageField: XCUIElement {
        app.textViews[Locators.ActiveConversationPage.inputField.rawValue]
    }

    var sendButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sendButton.rawValue]
    }

    var conversationBackButton: XCUIElement {
        // The conversation now uses the system back button (see `configureBackButton(hasUnread:)`),
        // whose accessibility identifier is not exposed to XCUITest. Match it positionally, the same
        // way `OptionsOnSettingsPage` taps the Settings back button.
        app.navigationBars.buttons.element(boundBy: 0)
    }

    var senderNameLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.authorName.rawValue].firstMatch
    }

    var messageLabels: XCUIElementQuery {
        app.descendants(matching: .textView).matching(identifier: Locators.ActiveConversationPage.message.rawValue)
    }

    var mentionButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.mentionButton.rawValue]
    }

    func getSenderName() -> String {
        senderNameLabel.label
    }

    var conversationTitleButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.conversationTitleButton.rawValue].firstMatch
    }

    var conversationDetailsButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.conversationDetailsButton.rawValue]
    }

    var selfDeletingMessageButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.ephemeralTimeSelectionButton.rawValue]
    }

    var imageCell: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.imageCell.rawValue].firstMatch
    }

    var videoCell: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCell.rawValue].firstMatch
    }

    var videoPlayButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoPlayButton.rawValue].firstMatch
    }

    var userRemovedSystemMessage: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationsPage.userRemovedSystemMessage.rawValue]
    }

    var fileLabels: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.ActiveConversationPage.sharedFileLabel.rawValue)
    }

    var fileDetailLabels: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.ActiveConversationPage.sharedFileDetailsLabel.rawValue)
    }

    var fileTypeIcons: XCUIElementQuery {
        app.images.matching(identifier: Locators.ActiveConversationPage.fileTypeIcon.rawValue)
    }

    func fileAttachment(name: String, type: String) -> XCUIElement {
        app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", name, type)
        ).firstMatch
    }

    func fileLabel(containing name: String) -> XCUIElement {
        fileLabels.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
    }

    func fileDetails(containing text: String) -> XCUIElement {
        fileDetailLabels.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    var labelSharedDriveIsOn: XCUIElement {
        app.links.containing(NSPredicate(
            format: "value CONTAINS[c] %@",
            Locators.ActiveConversationPage.labelSharedDriveON.rawValue
        )).firstMatch
    }

    var sharedDriveButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sharedDriveButton.rawValue]
    }

    var labelSelfDeletingMessageIsOFF: XCUIElement {
        app.staticTexts[Locators.ActiveConversationPage.labelSelfDeletingMessagesOFF.rawValue]
    }

    var sketchButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sketchButton.rawValue]
    }

    var canvas: XCUIElement {
        app.otherElements[Locators.ActiveConversationPage.canvas.rawValue]
    }

    var sendCanvasButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.canvasSendButton.rawValue]
    }

    var attachmentImagePreview: XCUIElement {
        app.images[Locators.ActiveConversationPage.attachmentImagePreview.rawValue]
    }

    var classifiedBanner: XCUIElement {
        app.otherElements[Locators.ActiveConversationPage.classifiedBanner.rawValue]
    }

    var guestsArePresentBanner: XCUIElement {
        app.staticTexts[Locators.ActiveConversationPage.guestsArePresent.rawValue]
    }

    var conversationBackground: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.conversationBackground.rawValue].firstMatch
    }

    var userLeftSystemMessage: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationsPage.useLeftSystemMessage.rawValue]
    }

    var photoButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.photoButton.rawValue]
    }

    var uploadFileButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.uploadFileButton.rawValue].firstMatch
    }

    var locationButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.locationButton.rawValue].firstMatch
    }

    var sendLocationButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sendLocation.rawValue].firstMatch
    }

    var selectedAddress: XCUIElement {
        app.staticTexts[Locators.ActiveConversationPage.selectedAddress.rawValue].firstMatch
    }

    var locationCell: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.locationCell.rawValue].firstMatch
    }

    var browseFileOption: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.browse.rawValue].firstMatch
    }

    var openFileButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.open.rawValue].firstMatch
    }

    func fileCell(named fileName: String) -> XCUIElement {
        let displayedFileName = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension

        return app.cells["\(displayedFileName), \(fileExtension)"].firstMatch
    }

    /// Photos grid sorts newest-first; 3 seeded videos always occupy indices 0-2,
    /// so the first real image sits at index 3.
    func imageToChoose(at index: Int = 3) -> XCUIElement {
        app.images.element(boundBy: index).firstMatch
    }

    func videoToChoose(at index: Int = 0) -> XCUIElement {
        app.images.element(boundBy: index).firstMatch
    }

    var okToSend: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.ok.rawValue].firstMatch
    }

    var audioButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.audioButton.rawValue].firstMatch
    }

    var startRecording: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.startRecording.rawValue].firstMatch
    }

    var stopRecording: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.stopRecording.rawValue].firstMatch
    }

    var heliumButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.helium.rawValue].firstMatch
    }

    var sendAudioButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sendAudio.rawValue].firstMatch
    }

    var playAudioFile: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.playAudioFile.rawValue].firstMatch
    }

    var recordingTimeLabel: XCUIElement {
        app.staticTexts[Locators.ActiveConversationPage.recordingTime.rawValue]
    }

    var showOtherRowButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.showOtherRowButton.rawValue]
    }

    var pingButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.pingButton.rawValue]
    }

    var openOngoingCallButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.openOngoingCallButton.rawValue]
    }

    var linkPreviewCell: XCUIElement {
        app.cells[Locators.ActiveConversationPage.linkPreviewCell.rawValue].firstMatch
    }

    func fetchMessages() -> [String] {
        var messages: [String] = []
        for i in 0 ..< messageLabels.count {
            let element = messageLabels.element(boundBy: i)
            if let value = element.value as? String {
                // Normalize spaces inserted by UI
                let normalized = value.replacingOccurrences(of: "\u{00A0}", with: " ")
                messages.append(normalized)
            }
        }
        return messages
    }

    func fetchFileNames() -> [String] {
        var files: [String] = []
        for i in 0 ..< fileLabels.count {
            let element = fileLabels.element(boundBy: i)
            files.append(element.label)
        }
        return files
    }

    func fetchFileDetails() -> [String] {
        var files: [String] = []
        for i in 0 ..< fileDetailLabels.count {
            let element = fileDetailLabels.element(boundBy: i)
            files.append(element.label)
        }
        return files
    }

    func sendMessage(_ message: String) throws -> ActiveConversationPage {
        try inputMessageField.tapIfKeyboardNotFocused().typeText(message)
        sendButton.tap()
        return self
    }

    @discardableResult
    func goBackToConversationPage() throws -> ConversationsPage {
        conversationBackButton.waitAndTap()
        return try ConversationsPage()
    }

    func openConversationDetails() throws -> ConversationDetailsPage {
        conversationTitleButton.waitAndTap()
        conversationDetailsButton.waitAndTap()
        return try ConversationDetailsPage()
    }

    func chooseUser(nameOfUser: String) {
        let userCell = app.cells
            .matching(identifier: Locators.ActiveConversationPage.userCellName.rawValue)
            .containing(.staticText, identifier: nameOfUser)
            .firstMatch

        userCell.tap()
    }

    func mentionUserAndSendMessage(nameOfUser: String) throws -> ActiveConversationPage {
        mentionButton.tap()
        chooseUser(nameOfUser: nameOfUser)
        sendButton.tapAndWait()
        return self
    }

    @discardableResult
    func typeMessageAndAttachSketch(_ message: String) throws -> ActiveConversationPage {
        try inputMessageField.tapIfKeyboardNotFocused().typeText(message)
        sketchButton.tap()
        canvas.tap()
        sendCanvasButton.tap()
        return self
    }

    func waitToUploadToFinishAndSend() {
        XCTAssertTrue(attachmentImagePreview.waitForExistence(timeout: 3))
        sendButton.waitAndTap()
        XCTAssertTrue(attachmentImagePreview.waitForNonExistence(timeout: 10))
    }

    func openSharedDrive() throws -> SharedDriveFilesPage {
        conversationTitleButton.waitAndTap()
        sharedDriveButton.tap()
        return try SharedDriveFilesPage()
    }

    func verifyCanAccessSharedDrive() {
        conversationTitleButton.waitAndTap()
        XCTAssertTrue(sharedDriveButton.exists)
    }

    @MainActor
    @discardableResult
    func verifyConversationBackgroundColor(
        _ color: AccountSettingsPage.ProfileColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> ActiveConversationPage {
        let background = conversationBackground
        XCTAssertTrue(
            background.waitForExistence(timeout: 5),
            "Conversation background element did not appear",
            file: file,
            line: line
        )
        let backgroundColor = try XCTUnwrap(
            background.value as? String,
            "Conversation background color value did not appear",
            file: file,
            line: line
        )
        XCTAssertNotEqual(
            backgroundColor,
            "default",
            "Conversation background should not be default when accentID \(color.accentID) is selected",
            file: file,
            line: line
        )
        let selfUser = try await UserHelper.default.selfUserAPI.getSelfUser()
        XCTAssertEqual(
            selfUser.accentID,
            color.accentID,
            "Self user accent ID should match \(color.accentID)",
            file: file,
            line: line
        )
        return self
    }

    func openPhotosAndGrantPermission() throws -> ActiveConversationPage {
        photoButton.waitAndTap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let allowButton = springboard.buttons["Allow"].firstMatch
        if allowButton.waitForExistence(timeout: 2) {
            allowButton.tap()
        }

        let allowFullAccessButton = springboard.buttons[
            Locators.ActiveConversationPage.allowFullAccess.rawValue
        ].firstMatch
        if allowFullAccessButton.waitForExistence(timeout: 2) {
            allowFullAccessButton.tap()
        }

        app.activate()
        return self
    }

    func openPhotos() throws -> ActiveConversationPage {
        photoButton.waitAndTap()
        return self
    }

    func selectImageAndSend(at index: Int = 3) throws -> ActiveConversationPage {
        if !imageToChoose(at: index).waitForExistence(timeout: 2) {
            photoButton.waitAndTap()
        }
        imageToChoose(at: index).waitAndTap()

        XCTAssertTrue(
            okToSend.waitForExistence(timeout: 3),
            "OK button did not appear after selecting media"
        )
        okToSend.waitAndTap()
        return self
    }

    func selectVideoAndSend(at index: Int = 0) throws -> ActiveConversationPage {
        if !videoToChoose(at: index).waitForExistence(timeout: 2) {
            photoButton.waitAndTap()
        }
        videoToChoose(at: index).waitAndTap()

        XCTAssertTrue(
            okToSend.waitForExistence(timeout: 3),
            "OK button did not appear after selecting media"
        )
        okToSend.waitAndTap()
        return self
    }

    @discardableResult
    func uploadFile(named fileName: String = "testFile.pdf") -> ActiveConversationPage {
        if !uploadFileButton.waitForExistence(timeout: 2) || !uploadFileButton.isHittable {
            showOtherRowButton.waitAndTap()
        }

        uploadFileButton.waitAndTap()
        browseFileOption.waitAndTap()

        if browseFileOption.waitForExistence(timeout: 3), !browseFileOption.isSelected {
            browseFileOption.tap()
        }

        XCTAssertTrue(
            fileCell(named: fileName).waitForExistence(timeout: 5),
            "Seeded file '\(fileName)' didn't show up"
        )
        fileCell(named: fileName).waitAndTap()

        XCTAssertTrue(
            openFileButton.waitForExistence(timeout: 5),
            "Open button didn't show up"
        )
        openFileButton.waitAndTap()
        return self
    }

    @MainActor
    @discardableResult
    func recordAudioAndSend() async throws -> ActiveConversationPage {
        audioButton.waitAndTap()
        app.dismissAllowIfPresent()

        if !startRecording.waitForExistence(timeout: 1) || !startRecording.isHittable {
            if audioButton.waitForExistence(timeout: 2), audioButton.isHittable {
                audioButton.tap()
            }
        }
        startRecording.waitAndTap()
        XCTAssertTrue(
            stopRecording.waitForExistence(timeout: 5),
            "Audio recording not started"
        )

        stopRecording.waitAndTap()
        heliumButton.waitAndTap()
        sendAudioButton.waitAndTap()
        return self
    }

    func receivedPing(for sender: String) -> XCUIElement {
        let label = NSPredicate(
            format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
            sender,
            "pinged"
        )
        return app.otherElements.containing(label).firstMatch
    }

    @discardableResult
    func sendPing() -> ActiveConversationPage {
        showOtherRowButton.waitAndTap()
        pingButton.waitAndTap()
        return self
    }

    @discardableResult
    func verifyPingSent(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> ActiveConversationPage {
        XCTAssertTrue(
            app.otherElements.containing(
                NSPredicate(format: "label CONTAINS %@", "You pinged")
            ).firstMatch.waitForExistence(timeout: 2),
            "Expected ping message not found",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func selectAndSendLocation() -> ActiveConversationPage {
        showOtherRowButton.waitAndTap()
        locationButton.waitAndTap()
        app.dismissAllowIfPresent()
        XCTAssertTrue(
            selectedAddress.waitForExistence(timeout: 5),
            "Selected address did not appear"
        )
        sendLocationButton.waitAndTap()
        return self
    }

    @discardableResult
    func verifyLocationShared() -> ActiveConversationPage {
        XCTAssertTrue(
            locationCell.waitForExistence(timeout: 10),
            "Expected location message not found"
        )
        return self
    }

    func openLocationInDefaultMapsApp(locationName: String) {
        let locationMap = app.descendants(matching: .any)
            .matching(identifier: Locators.ActiveConversationPage.locationMap.rawValue)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", locationName))
            .firstMatch

        XCTAssertTrue(
            locationMap.waitAndTap(),
            "Location \(locationName) could not be opened"
        )

        let mapsApp = XCUIApplication(bundleIdentifier: "com.apple.Maps")
        XCTAssertTrue(
            mapsApp.wait(for: .runningForeground, timeout: 5),
            "Expected location to open in Maps"
        )
    }

    @discardableResult
    func verifyMessageSent(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ActiveConversationPage {
        XCTAssertTrue(
            app.textViews.matching(NSPredicate(format: "label == %@", message)).firstMatch.waitForExistence(timeout: 5),
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func verifySharedFile(
        name: String,
        type: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ActiveConversationPage {
        let attachment = fileAttachment(name: name, type: type)

        XCTAssertTrue(
            attachment.waitForExistence(timeout: 5),
            "Expected \(type) attachment '\(name)' not found",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func verifyGIFReceived(
    ) -> ActiveConversationPage {
        XCTAssertTrue(
            imageCell.waitForExistence(timeout: 10),
            "Expected GIF image not found",
        )

        XCTAssertTrue(
            waitForChangingFrame(in: imageCell),
            "Expected GIF image to animate",
        )

        return self
    }

    private func waitForChangingFrame(
        in element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if isChangingFrame(in: element) {
                return true
            }
        } while Date() < deadline

        return false
    }

    private func isChangingFrame(
        in element: XCUIElement,
        frameCount: Int = 6,
        delay: TimeInterval = 0.2
    ) -> Bool {
        var screenshots = Set<Data>()

        for index in 0 ..< frameCount {
            screenshots.insert(element.screenshot().pngRepresentation)
            guard index < frameCount - 1 else { continue }
            RunLoop.current.run(until: Date().addingTimeInterval(delay))
        }

        return screenshots.count > 1
    }

    @discardableResult
    func verifyReadReceiptsSystemMessage(
        enabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ActiveConversationPage {
        let identifier = enabled
            ? Locators.ActiveConversationPage.readReceiptsEnabledSystemMessage.rawValue
            : Locators.ActiveConversationPage.readReceiptsDisabledSystemMessage.rawValue
        XCTAssertTrue(
            app.descendants(matching: .any)[identifier].firstMatch.waitForExistence(timeout: 10),
            "Expected read-receipts system message with identifier '\(identifier)' not found",
            file: file,
            line: line
        )
        return self
    }

    func verifyLinkPreviewCell(
        shouldExist: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ActiveConversationPage {
        if shouldExist {
            XCTAssertTrue(
                linkPreviewCell.waitForExistence(timeout: 10),
                "Link preview cell did not appear",
                file: file,
                line: line
            )
        } else {
            XCTAssertFalse(
                linkPreviewCell.waitForExistence(timeout: 3),
                "Link preview cell should not appear",
                file: file,
                line: line
            )
        }
        return self
    }

    func initiateCall() throws -> OngoingCallPage {
        videoCallButton.waitAndTap()
        app.dismissAllowIfPresent()
        return try OngoingCallPage()
    }

    func resumeCallUI() throws -> OngoingCallPage {
        openOngoingCallButton.waitAndTap()
        return try OngoingCallPage()
    }

    @discardableResult
    func verifyNoCallOngoingAfterHangUp() throws -> ActiveConversationPage {
        XCTAssertTrue(
            openOngoingCallButton.waitForNonExistence(timeout: 4),
            "Ongoing call still visible after hanging up the call"
        )
        return self
    }
}
