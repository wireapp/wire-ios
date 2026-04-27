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
import XCTest

final class OneOnOneMessagingTests: WireUITestCase {

    @MainActor
    func testSendImageInOneOnOneConversation_TC_8820() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1
            )

        // WHEN
        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(teamOwner.username)
            .tapSearchedUserCell()
            .tapStartConversationButton()
            .openPhotosAndGrantPermission()
            .selectImageAndSend()

        // THEN
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 2), "No Image cell found"
        )
    }

    @MainActor
    func testReceiveImageInOneOnOneConversation_TC_8827() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1
            )

        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(teamOwner.username)
            .tapSearchedUserCell()
            .tapStartConversationButton()

        let (conversationId, domain) = try await userHelper.getConversationId(matching: .conversationType(.group))

        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        let imageURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData/Img/testImage.jpg")
        let imageExtension = imageURL.pathExtension

        // WHEN member send image
        try await testServicesClient.sendImage(
            user: teamOwner,
            fileURL: imageURL,
            type: imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 2),
            "Expected image attachment not found"
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamOwner.name,
            "Sender info didn't match expected value \(teamOwner.name)"
        )
    }
}
