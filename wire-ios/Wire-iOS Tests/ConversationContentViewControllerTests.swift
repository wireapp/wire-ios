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

final class ConversationContentViewControllerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    private var sut: ConversationContentViewController!
    private var mockConversation: ZMConversation!
    private var userSession: UserSessionMock!
    private var mockMessage: MockMessage!
    private var mockMainCoordinator: MainCoordinator!

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {

        coreDataFixture = CoreDataFixture()

        mockConversation = createTeamGroupConversation()

        mockMessage = MockMessageFactory.textMessage(withText: "Message")
        mockMessage.senderUser = MockUserType.createSelfUser(name: "Alice")
        mockMessage.conversation = mockConversation
        mockMessage.deliveryState = .read
        mockMessage.needsReadConfirmation = true

        userSession = UserSessionMock()

        sut = ConversationContentViewController(
            conversation: mockConversation,
            mediaPlaybackManager: nil,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol()
        )

        // Call the setup codes in viewDidLoad
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockMessage = nil
        userSession = nil
        coreDataFixture = nil
        mockMainCoordinator = nil
    }

    func testThatDeletionDialogIsCreated() throws {
        // Notice: view arguemnt is used for iPad idiom. We should think about test it with iPad simulator that the alert shows in a popover which points to the view.
        let view = UIView()

        // create deletionDialogPresenter
        let message = MockMessageFactory.textMessage(withText: "test")
        sut.messageAction(actionId: .delete, for: message, view: view)

        try verify(matching: sut.deletionDialogPresenter!.deleteAlert(message: mockMessage, sourceView: view, userSession: userSession) { _ in })
    }
}
