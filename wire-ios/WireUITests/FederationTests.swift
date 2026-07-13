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

/// [core-messenger]
final class FederationTests: WireUITestCase {

    /// [critical]
    @MainActor
    func testConnectFederatedUsers_TC_9459() async throws {

        try switchBackend(target: .bella)
        let bellaTeam = try await UserHelper.instance(backend: .bella).registerTeam(withMemberCount: 0)
        _ = try await loginToBackend(user: bellaTeam.teamOwner)

        try switchBackend(target: .anta)
        let antaTeam = try await UserHelper.instance(backend: .anta).registerTeam(withMemberCount: 0)
        let conversationsPage = try await loginToBackend(user: antaTeam.teamOwner)

        // WHEN
        let federatedHandle = "@\(bellaTeam.teamOwner.username)@\(BackendTarget.bella.domainInfo)"
        let activeConversationPage = try conversationsPage
            .tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(federatedHandle)
            .tapSearchedUserCell()
            .sendConnectionRequest()
            .closeProfilePage()
            .closeNewConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: bellaTeam.teamOwner.name)
            .tapConnectionRequestsCell()
            .acceptConnectionRequest()

        // THEN
        XCTAssertTrue(activeConversationPage.classifiedBanner.exists)
        _ = try activeConversationPage.goBackToConversationPage()

        XCTAssertTrue(conversationsPage.conversationCell.exists)
        let conversationName = try XCTUnwrap(conversationsPage.getNameLabel())
        XCTAssertEqual(conversationName, antaTeam.teamOwner.name, "name didn't match \(conversationName)")
    }

}
