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

import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationViewControllerGuestBarTests: XCTestCase, CoreDataFixtureTestHelper {

    private var mockMainCoordinator: AnyMainCoordinator!
    private var sut: ConversationViewController!
    private var userSession: UserSessionMock!
    var coreDataFixture: CoreDataFixture!

    @MainActor
    override func setUp() async throws {
        coreDataFixture = try await CoreDataFixture()
        userSession = UserSessionMock(mockUser: .createSelfUser(name: "Bob"))
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
        let conversation = createTeamGroupConversation()
        sut = ConversationViewController(
            conversation: conversation,
            visibleMessage: nil,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol(),
            mediaPlaybackManager: nil,
            classificationProvider: nil,
            networkStatusObservable: MockNetworkStatusObservable(),
            getParticipantImageSourceUseCase: MockGetParticipantImageSourceUseCaseProtocol(),
            wireMessagingFactory: MockWireMessagingFactoryProtocol.makeDefault()
        )
    }

    override func tearDown() {
        sut = nil
        mockMainCoordinator = nil
        userSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func testAllKnownStatesAreHandled() {
        typealias BannerStrings = L10n.Localizable.Conversation.Banner

        assertLabel(
            for: [.visibleRemotes],
            expected: BannerStrings.remotesPresent
        )

        assertLabel(
            for: [.visibleExternals],
            expected: BannerStrings.externalsPresent
        )

        assertLabel(
            for: [.visibleGuests],
            expected: BannerStrings.guestsPresent
        )

        assertLabel(
            for: [.visibleApps],
            expected: BannerStrings.appsActive
        )

        assertLabel(
            for: [.visibleRemotes, .visibleExternals],
            expected: BannerStrings.remotesExternalsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleGuests],
            expected: BannerStrings.remotesGuestsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleApps],
            expected: BannerStrings.remotesAppsPresent
        )

        assertLabel(
            for: [.visibleExternals, .visibleGuests],
            expected: BannerStrings.externalsGuestsPresent
        )

        assertLabel(
            for: [.visibleExternals, .visibleApps],
            expected: BannerStrings.externalsAppsPresent
        )

        assertLabel(
            for: [.visibleGuests, .visibleApps],
            expected: BannerStrings.guestsAppsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleExternals, .visibleGuests],
            expected: BannerStrings.remotesExternalsGuestsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleExternals, .visibleApps],
            expected: BannerStrings.remotesExternalsAppsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleGuests, .visibleApps],
            expected: BannerStrings.remotesGuestsAppsPresent
        )

        assertLabel(
            for: [.visibleExternals, .visibleGuests, .visibleApps],
            expected: BannerStrings.externalsGuestsAppsPresent
        )

        assertLabel(
            for: [.visibleRemotes, .visibleExternals, .visibleGuests, .visibleApps],
            expected: BannerStrings.remotesExternalsGuestsAppsPresent
        )
    }

    // MARK: - Helper Method

    private func assertLabel(
        for state: ZMConversation.ExternalParticipantsState,
        expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = sut.label(for: state)
        XCTAssertEqual(result, expected, file: file, line: line)
    }

    func createTeamGroupConversation() -> ZMConversation {
        ZMConversation.createTeamGroupConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

}
