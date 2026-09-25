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

final class AddParticipantsViewModelTests: XCTestCase {

    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        mockSelfUser = SelfUser.provider?.providedSelfUser as? MockUserType
        mockSelfUser.canCreateService = true
    }

    override func tearDown() {
        mockSelfUser = nil
        super.tearDown()
    }

    /// Apps must never be offered when creating a brand new conversation, regardless of whether apps/bots are
    /// otherwise enabled for the team - the apps group selector should simply never show up in `.create` context.
    func testThatBotCanBeAdded_IsAlwaysFalse_ForCreateContext() {
        let values = ConversationCreationValues(
            isChannel: false,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true,
            name: "",
            participants: [],
            allowGuests: true,
            encryptionProtocol: .proteus,
            selfUser: mockSelfUser
        )

        let sut = AddParticipantsViewModel(
            context: .create(values),
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true
        )

        XCTAssertFalse(sut.botCanBeAdded)
    }

    /// Regression guard: the `.create` (new-conversation) flow must never add the apps group selector to its
    /// view hierarchy, even though the same search path now also surfaces human team collaborators.
    func testThatCreateContext_NeverAddsSearchGroupSelector() throws {
        let values = ConversationCreationValues(
            isChannel: false,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true,
            name: "",
            participants: [],
            allowGuests: true,
            encryptionProtocol: .proteus,
            selfUser: mockSelfUser
        )
        let userSession = UserSessionMock(mockUser: mockSelfUser)

        let sut = try XCTUnwrap(AddParticipantsViewController(
            context: .create(values),
            userSession: userSession,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true
        ))

        XCTAssertFalse(sut.view.subviews.contains { $0 is SearchGroupSelector })
    }

}
