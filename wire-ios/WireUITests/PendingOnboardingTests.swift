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

import WireNetwork
import XCTest

/// [core-messenger, connections]
final class PendingOnboardingTests: WireUITestCase {

    @MainActor
    func testSearchForTeammateWhoseOnboardingIsPending_TC_12185() async throws {
        let fixture = try await createFixture(onboardTeammate: false)

        let searchPage = try searchForTeammate(fixture)

        searchPage.verifySearchResultWithoutPendingBadge(named: fixture.teammate.name)
    }

    @MainActor
    func testOpenProfileOfTeammateWhoseOnboardingIsPending_TC_12186() async throws {
        let fixture = try await createFixture(onboardTeammate: false)

        let profile = try searchForTeammate(fixture).openSearchResult(named: fixture.teammate.name)

        profile.verifyName(fixture.teammate.name)
    }

    @MainActor
    func testPendingTeammateProfileShowsSetupHint_TC_12187() async throws {
        let fixture = try await createFixture(onboardTeammate: false)
        let profile = try searchForTeammate(fixture).openSearchResult(named: fixture.teammate.name)

        // The final copy is pending review against TC-12187; assert the currently agreed product wording for now.
        profile.verifyPendingOnboardingHint(name: fixture.teammate.name)
    }

    @MainActor
    func testCannotStartConversationWithPendingTeammate_TC_12188() async throws {
        let fixture = try await createFixture(onboardTeammate: false)
        let conversationsBefore = try await UserHelper.default.getConversationIds()
        let profile = try searchForTeammate(fixture).openSearchResult(named: fixture.teammate.name)

        profile.verifyPendingOnboardingHint(name: fixture.teammate.name)
            .attemptDisabledStartConversation()
            .verifyName(fixture.teammate.name)

        let conversationsAfter = try await UserHelper.default.getConversationIds()
        XCTAssertEqual(
            Set(conversationsAfter),
            Set(conversationsBefore),
            "Attempting the disabled action must not create a conversation"
        )
    }

    @MainActor
    func testSearchAndOpenFullyOnboardedTeammateProfile_TC_12189() async throws {
        let fixture = try await createFixture(onboardTeammate: true)

        let profile = try searchForTeammate(fixture)
            .verifySearchResultWithoutPendingBadge(named: fixture.teammate.name)
            .openSearchResult(named: fixture.teammate.name)

        profile.verifyName(fixture.teammate.name)
            .verifyStartConversationEnabled(true)
            .verifyNoPendingOnboardingHint()
    }

    @MainActor
    func testStartConversationWithFullyOnboardedTeammate_TC_12190() async throws {
        let fixture = try await createFixture(onboardTeammate: true)
        let profile = try searchForTeammate(fixture).openSearchResult(named: fixture.teammate.name)
        let conversationsBefore = try await UserHelper.default.getConversationIds()

        let conversation = try profile.verifyStartConversationEnabled(true).tapStartConversationButton()

        XCTAssertTrue(conversation.pageMainElement.exists, "The new conversation did not open")
        try await waitForNewConversation(comparedWith: Set(conversationsBefore))
    }

    // MARK: - Fixtures

    private struct Fixture {
        let teammate: UserInfo
        let conversationsPage: ConversationsPage
    }

    @MainActor
    private func createFixture(onboardTeammate: Bool) async throws -> Fixture {
        let helper = UserHelper.default
        let (ownerID, owner) = try await helper.registerUserAsTeamOwner()
        try await ssoHelper.enableSSOFeature(teamID: XCTUnwrap(owner.teamID))
        let teammate = try await ssoHelper.createSCIMManagedSSOUser(
            owner: owner,
            ssoUser: UserGenerator.generateUniqueUserInfo()
        )
        let teammateID = QualifiedID(id: try XCTUnwrap(UUID(uuidString: teammate.id)), domain: ownerID.domain)

        // Verify the pending fixture without ever authenticating the teammate or creating their client.
        try await waitForContactStatus(.nonContactable, userID: teammateID)

        if onboardTeammate {
            let conversations = try await WelcomePage()
                .enterSSOCode(ssoHelper.getSSOCode())
                .ssoWebLogin(email: teammate.email, password: teammate.password)
                .acceptFirstTimeAlert()
                .acceptPopup()
            try await waitForContactStatus(.contactable, userID: teammateID)
            _ = try conversations.openUserProfilePage().tapAddAccountOrTeamButton()
        }

        let conversationsPage = try app.loginUser(email: owner.email, password: owner.password).acceptPopup()
        return Fixture(teammate: teammate, conversationsPage: conversationsPage)
    }

    @MainActor
    private func searchForTeammate(_ fixture: Fixture) throws -> NewConversationPage {
        try fixture.conversationsPage.tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(fixture.teammate.username)
    }

    @MainActor
    private func waitForContactStatus(_ expected: ContactStatus, userID: QualifiedID) async throws {
        for attempt in 0 ..< 15 {
            if try await UserHelper.default.getContactStatus(for: userID) == expected { return }
            if attempt < 14 { try await Task.sleep(for: .seconds(1)) }
        }
        throw RuntimeError("Teammate fixture did not reach the expected contact status: \(expected)")
    }

    @MainActor
    private func waitForNewConversation(comparedWith previousIDs: Set<QualifiedID>) async throws {
        for attempt in 0 ..< 15 {
            let currentIDs = Set(try await UserHelper.default.getConversationIds())
            if !currentIDs.subtracting(previousIDs).isEmpty { return }
            if attempt < 14 { try await Task.sleep(for: .seconds(1)) }
        }
        throw RuntimeError("Starting a conversation did not create a backend conversation")
    }

}
