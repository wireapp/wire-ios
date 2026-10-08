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

import WireFoundation
import WireUtilities
import XCTest

/// [collaboration]
final class WireDriveTests: WireUITestCase {

    override func additionalDeveloperFlags() -> [DeveloperFlag: Bool] {
        [.simulateDriveOffline: false]
    }

    private func createDriveEnabledConversation(
        _ conversation: CreateConversationOption,
        memberCount: Int = 2
    ) async throws -> UserInfo {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: memberCount,
            conversation: conversation,
            driveEnabled: true
        )
        return teamOwner
    }

    private func createDriveEnabledConversationWithGuest(groupName: String) async throws -> UserInfo {
        try await createDriveEnabledConversationWithOwnerAndGuest(groupName: groupName).guest
    }

    private func createDriveEnabledConversationWithOwnerAndGuest(
        groupName: String
    ) async throws -> (owner: UserInfo, guest: UserInfo) {
        let (owner, guest) = try await UserHelper.default.connectDriveEnabledTeamUserWithGuestUser()

        let domain = BackendTarget.staging.domainInfo
        let ownerQualifiedID = WireFoundation.QualifiedID(id: try XCTUnwrap(UUID(uuidString: owner.id)), domain: domain)
        let guestQualifiedID = WireFoundation.QualifiedID(id: try XCTUnwrap(UUID(uuidString: guest.id)), domain: domain)

        let participantsQualifiedIDs = [
            ownerQualifiedID,
            guestQualifiedID
        ]

        try await UserHelper.default.createGroupConversations(
            qualifiedIds: participantsQualifiedIDs,
            owner: owner,
            groupName: groupName,
            driveEnabled: true
        )

        return (owner, guest)
    }

    private func loginAndOpenConversation(for user: UserInfo) throws -> ActiveConversationPage {
        try app
            .loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openConversation()
    }

    private func verifyDriveEnabledConversation(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(activeConversationPage.labelSharedDriveIsOn.waitForExistence(timeout: 2))
        XCTAssertTrue(activeConversationPage.labelSelfDeletingMessageIsOFF.exists)
        XCTAssertFalse(activeConversationPage.selfDeletingMessageButton.isHittable)

        activeConversationPage.conversationTitleButton.waitAndTap()

        XCTAssertTrue(activeConversationPage.sharedDriveButton.exists)
    }

    private func createTeamAndEnableDrive(
        memberCount: Int = 2,
        channelEnabled: Bool = false
    ) async throws -> (teamOwner: UserInfo, teamMembers: [UserInfo]) {
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: memberCount)
        let teamID = try XCTUnwrap(teamOwner.teamID)

        if channelEnabled {
            try await UserHelper.default.unlockAndEnableChannelFeature(teamID: teamID)
        }

        try await UserHelper.default.unlockAndEnableDriveFeature(teamID: teamID)
        return (teamOwner, teamMembers)
    }

    private func uploadSketchAttachment(
        message: String,
        for user: UserInfo
    ) throws -> ActiveConversationPage {
        let activeConversationPage = try loginAndOpenConversation(for: user)
            .typeMessageAndAttachSketch(message)

        activeConversationPage.waitToUploadToFinishAndSend()
        return activeConversationPage
    }

    private func uploadSketchAndOpenSharedDrive(
        message: String,
        for user: UserInfo
    ) throws -> SharedDriveFilesPage {
        try uploadSketchAttachment(message: message, for: user)
            .openSharedDrive()
    }

    /// [critical]
    @MainActor
    func testCreateGroupConversationWithDrive_TC_8955() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers) = try await createTeamAndEnableDrive()

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enableShareDriveSwitch()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        // THEN
        verifyDriveEnabledConversation(on: activeConversationPage)
    }

    /// [critical]
    @MainActor
    func testCreateChannelConversationWithDrive_TC_8954() async throws {

        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers) = try await createTeamAndEnableDrive(channelEnabled: true)

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapNewChannelButton()
            .enableShareDriveSwitch()
            .enterChannelName(channelName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        // THEN
        verifyDriveEnabledConversation(on: activeConversationPage)
    }

    /// [critical]
    @MainActor
    func testShareSketchImageWithTextMessageInDriveEnabledGroup_TC_8956() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        // THEN
        XCTAssertTrue(activeConversationPage.attachmentImagePreview.waitForExistence(timeout: 2))
        XCTAssertEqual(activeConversationPage.inputMessageField.value as? String, message)
    }

    /// [critical]
    @MainActor
    func testAccessImageSharedInDriveEnabledGroup_TC_8957() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: message, for: teamOwner)

        // THEN
        try sharedDrivePage
            .verifyFileTypeAndMetadata(name: teamOwner.name)
    }

    /// [critical]
    @MainActor
    func testDeletingFileFromDriveMovesFileToRecycleBin_TC_8958() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: message, for: teamOwner)

        let sharedFileName = sharedDrivePage.fileNameText

        let recycleBinPage = try sharedDrivePage
            .openMoreOptionsOnFileAndDelete()
            .openRecycleBin()

        // THEN
        XCTAssertTrue(recycleBinPage.verifyFileMovedToRecycleBin(fileName: sharedFileName))

    }

    /// [critical]
    @MainActor
    func testRestoringFileFromRecycleBinToDrive_TC_8959() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        var sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: message, for: teamOwner)

        let sharedFileName = sharedDrivePage.fileNameText

        sharedDrivePage = try sharedDrivePage
            .openMoreOptionsOnFileAndDelete()
            .openRecycleBin()
            .openMoreOptionsOnFileAndRestoreFile()
            .closeRecycleBin()

        // THEN
        XCTAssertTrue(sharedDrivePage.verifyFileMovedToSharedDrive(fileName: sharedFileName))
    }

    /// [critical]
    @MainActor
    func testDeletingFilePermanentelyFromRecycleBin_TC_8960() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        activeConversationPage.waitToUploadToFinishAndSend()

        let sharedDrivePage = try activeConversationPage
            .openSharedDrive()

        let recycleBinPage = try sharedDrivePage
            .openMoreOptionsOnFileAndDelete()
            .openRecycleBin()
            .deleteFilePermanently()

        // THEN
        XCTAssertTrue(recycleBinPage.verifyRecycleBinIsEmpty())
    }

    /// [critical]
    @MainActor
    func testCreatingFolder_TC_8961() async throws {

        // GIVEN
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)

        let folderName = "Test"
        let sharedDrivePage = try activeConversationPage
            .openSharedDrive()
            .createFolder()
            .enterFolderNameAndValidate(name: folderName)

        // THEN
        XCTAssertTrue(sharedDrivePage.verifyFolderIsCreated(folderName: folderName))
    }

    @MainActor
    func testCreatingFile_DocumentSpreadsheetPresentation_TC_12152() async throws {

        // GIVEN
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        var sharedDrivePage = try loginAndOpenConversation(for: teamOwner)
            .openSharedDrive()

        for (index, template) in [CreateFilePage.Template.document, .spreadsheet, .presentation].enumerated() {
            // WHEN
            let fileName = "Test\(index)"
            sharedDrivePage = try sharedDrivePage
                .createFile(template: template)
                .enterFileNameAndCreate(name: fileName)

            // THEN
            XCTAssertTrue(
                sharedDrivePage.verifyFileIsCreated(fileName: fileName, fileExtension: template.fileExtension),
                "\(template) should be created"
            )
        }
    }

    @MainActor
    func testMakeFileAvailableOffline_TC_12153() async throws {

        // GIVEN
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        let sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: "Attachment with Text", for: teamOwner)
        // The row label also holds the metadata (date, author) and gains "Available offline" once downloaded
        let sharedFileName = try XCTUnwrap(sharedDrivePage.fileNameText.components(separatedBy: ",").first)

        // WHEN
        try sharedDrivePage.makeFileAvailableOffline()
        XCTAssertTrue(sharedDrivePage.availableOfflineIcon.waitForExistence(timeout: 15))

        // Relaunch the app (keeping the session) with Drive simulating no network connection
        app.terminate()
        app.launchArguments = ["--useEnvStaging"]
        app.setDeveloperFlags([.useWireAuthentication: true, .simulateDriveOffline: true])
        app.launch()

        let offlineSharedDrivePage = try ConversationsPage()
            .openConversation()
            .openSharedDrive()

        // THEN
        XCTAssertTrue(offlineSharedDrivePage.fileIcon.waitForExistence(timeout: 10))
        XCTAssertTrue(offlineSharedDrivePage.fileNameText.hasPrefix(sharedFileName))
        XCTAssertTrue(offlineSharedDrivePage.fileNameText.contains("Available offline"))
        XCTAssertTrue(offlineSharedDrivePage.availableOfflineIcon.exists)
    }

    @MainActor
    func testSortAndFilterFiles_TC_12154() async throws {

        // GIVEN - an image and a document in the shared drive
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        let documentName = "Zzz"
        let template = CreateFilePage.Template.document
        let sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: "Attachment with Text", for: teamOwner)
            .createFile(template: template)
            .enterFileNameAndCreate(name: documentName)
        let documentFullName = "\(documentName).\(template.fileExtension)"
        XCTAssertTrue(sharedDrivePage.verifyFileIsCreated(
            fileName: documentName,
            fileExtension: template.fileExtension
        ))

        // WHEN / THEN - sorting by name
        sharedDrivePage.sort(by: "name")
        XCTAssertTrue(sharedDrivePage.waitForFirstFile(startingWith: "IMG_"), "A-Z: image should come first")

        sharedDrivePage.sort(order: "descending")
        XCTAssertTrue(
            sharedDrivePage.waitForFirstFile(startingWith: documentFullName),
            "Z-A: document should come first"
        )

        // WHEN / THEN - filtering by type
        sharedDrivePage.filter(byType: "image")
        XCTAssertTrue(sharedDrivePage.fileRow(named: "IMG_").waitForExistence(timeout: 5))
        XCTAssertTrue(sharedDrivePage.fileRow(named: documentFullName).waitForNonExistence(timeout: 5))
    }

    /// [critical]
    @MainActor
    func testGuestWithViewerAccessHasLimitedActions_TC_12155() async throws {

        // GIVEN - the team owner shares a file in a conversation with a guest
        let groupName = "Team + Guest"
        let (owner, guest) = try await createDriveEnabledConversationWithOwnerAndGuest(groupName: groupName)

        let activeConversationPage = try app
            .loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversationWithGuest(groupName: groupName)
            .typeMessageAndAttachSketch("Attachment with Text")
        activeConversationPage.waitToUploadToFinishAndSend()

        // The app is relaunched with a fresh state (-resetData) to log in as the guest
        app.terminate()
        app.launch()

        // WHEN
        let guestConversationPage = try app
            .loginUser(email: guest.email, password: guest.password)
            .acceptPopup()
            .openConversationWithGuest(groupName: groupName)

        // THEN - the viewer access banner is shown
        XCTAssertTrue(guestConversationPage.driveViewerAccessBanner.waitForExistence(timeout: 5))

        // THEN - the photo/sketch/video/file upload actions are not offered
        for button in guestConversationPage.driveViewerDisabledInputBarButtons {
            XCTAssertTrue(button.exists, "\(button) should be in the input bar")
            XCTAssertFalse(button.isEnabled, "\(button) should be disabled")
        }

        // WHEN
        let sharedDrivePage = try guestConversationPage
            .openSharedDrive()
            .openNavigationBarMenu()

        // THEN - the "Create" actions are not offered, only the recycle bin is
        XCTAssertTrue(sharedDrivePage.openRecycleBinButton.waitForExistence(timeout: 3))
        XCTAssertFalse(sharedDrivePage.createFolderButton.exists)
        XCTAssertFalse(sharedDrivePage.createFileButton.exists)

        // WHEN
        sharedDrivePage.dismissMenu()
        try sharedDrivePage.openMoreOptionsOnFile()

        // THEN - Guest can only open a file
        XCTAssertTrue(sharedDrivePage.fileMenuActions.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(sharedDrivePage.fileMenuActions.count, 1)
        XCTAssertTrue(sharedDrivePage.openFileMenuAction.exists)
    }

    @MainActor
    func testGuestCanAccessSharedDriveOnly_TC_10875() async throws {
        // GIVEN
        let groupName = "Team + Guest"
        let guest = try await createDriveEnabledConversationWithGuest(groupName: groupName)

        // WHEN
        let conversationsPage = try app
            .loginUser(email: guest.email, password: guest.password)
            .acceptPopup()

        // THEN
        conversationsPage.verifyDriveTabButtonIsHidden()
        let activeConversationPage = try conversationsPage.openConversationWithGuest(groupName: groupName)
        XCTAssert(activeConversationPage.guestsArePresentBanner.exists)
        activeConversationPage.verifyCanAccessSharedDrive()
    }

    /// [critical, collaboration]
    @MainActor
    func testSearchingForFileByName_TC_8962() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let sharedDrivePage = try uploadSketchAndOpenSharedDrive(message: message, for: teamOwner)

        let sharedFileName = sharedDrivePage.fileNameText

        let positiveSearchTerm = sharedFileName.prefix(3).lowercased()
        let negativeSearchTerm = "my precious"

        let searchTextField = sharedDrivePage.searchTextField
        searchTextField.tap()

        searchTextField.typeText(positiveSearchTerm)
        XCTAssertTrue(
            sharedDrivePage.fileIcon.waitForExistence(timeout: 5)
        )
        let positiveSearchResults = sharedDrivePage.numberOfFilesInList

        searchTextField.typeText(negativeSearchTerm)
        XCTAssertTrue(
            sharedDrivePage.fileIcon.waitForNonExistence(timeout: 2)
        )
        let negativeSearchResults = sharedDrivePage.numberOfFilesInList

        // THEN
        XCTAssertEqual(positiveSearchResults, 1)
        XCTAssertEqual(negativeSearchResults, 0)
    }

    @MainActor
    func testVideoAndImagePreviewShown_TC_11684_11685() async throws {

        // GIVEN
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .openPhotosAndGrantPermission()
            .selectImageAndSendInDriveEnabledConversation()

        // THEN - image preview is shown after sending
        activeConversationPage.verifyImagePreviewIsVisible()

        // WHEN
        try activeConversationPage
            .selectVideoFromCameraRoll()
            .sendAttachments()

        // THEN - image and video preview shown together
        activeConversationPage.verifyVideoPreviewIsVisible()
    }
}
