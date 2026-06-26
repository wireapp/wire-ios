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

import WireDataModel
import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class GroupConversationHeaderViewSnapshotTests: ZMSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        DeveloperFlag.enableDrivePermissions.enable(false)
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    /// Named group — self is creator, other participants listed.
    func testNamedGroup_selfCreator_withParticipants() {
        let conversation = makeConversation(displayName: "Group Chat", participantNames: ["Alice", "Bob"])
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation))
    }

    /// Named group — self is creator with no other participants: the "with —" row must not appear.
    func testNamedGroup_selfCreator_noOtherParticipants() {
        let conversation = makeConversation(displayName: "Solo Group", participantNames: [])
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation))
    }

    /// Named group — another user is the creator.
    func testNamedGroup_otherCreator() {
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.name = "Charlie"
        otherUser.remoteIdentifier = UUID()
        let conversation = makeConversation(
            displayName: "Charlie's Group",
            creator: otherUser,
            participantNames: ["Alice"]
        )
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation))
    }

    /// Group with guests allowed — shows the GuestsAllowedView beneath the started cell.
    func testGroup_guestsAllowed() {
        let conversation = makeConversation(displayName: "Open Group", participantNames: ["Alice"])
        conversation.allowGuests = true
        let selfUser = makeSelfUser(isTeamMember: true, canAddUsers: true)
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation, selfUser: selfUser))
    }

    /// Group with drive enabled and guests allowed — shows the shared drive and message timer cells.
    func testGroup_guestsAllowed_withDriveEnabled() {
        DeveloperFlag.enableDrivePermissions.enable(true)
        let selfUser = makeSelfUser(isTeamMember: true, canAddUsers: true)
        let conversation = makeConversation(
            displayName: "Open Group",
            teamID: selfUser.teamIdentifier,
            participantNames: ["Alice"]
        )
        conversation.allowGuests = true
        conversation.cellsState = .ready
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation, selfUser: selfUser))
    }

    /// Group with Wire Drive enabled — shows the shared drive and message timer cells.
    func testGroup_wireDriveEnabled() {
        let selfUser = makeSelfUser(isTeamMember: true, canAddUsers: true)
        let conversation = makeConversation(
            displayName: "Drive Group",
            teamID: selfUser.teamIdentifier,
            participantNames: ["Alice"]
        )
        conversation.cellsState = .ready
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation, selfUser: selfUser))
    }

    /// Channel — uses channel-specific heading text.
    func testChannel() {
        let conversation = makeConversation(displayName: "My Channel", participantNames: ["Alice", "Bob"])
        conversation.groupType = .channel
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: makeView(conversation: conversation))
    }

    /// Dark mode variant.
    func testNamedGroup_selfCreator_withParticipants_darkMode() {
        let conversation = makeConversation(displayName: "Group Chat", participantNames: ["Alice", "Bob"])
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: makeView(conversation: conversation))
    }

    // MARK: - Helpers

    private func makeSelfUser(isTeamMember: Bool = false, canAddUsers: Bool = false) -> MockUserType {
        let selfUser = MockUserType.createDefaultSelfUser()
        if isTeamMember {
            selfUser.teamIdentifier = UUID()
        }
        selfUser.canAddUserToConversation = canAddUsers
        return selfUser
    }

    private func makeConversation(
        displayName: String? = nil,
        creator: ZMUser? = nil,
        teamID: UUID? = nil,
        participantNames: [String] = []
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        conversation.userDefinedName = displayName
        conversation.teamRemoteIdentifier = teamID

        let creatorUser = creator ?? ZMUser.selfUser(in: uiMOC)
        // `creator` is readonly in the public API; use KVC to set it from tests.
        conversation.setValue(creatorUser, forKey: "creator")
        conversation.addParticipantAndUpdateConversationState(user: creatorUser, role: nil)

        for name in participantNames {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.name = name
            user.remoteIdentifier = UUID()
            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        }

        return conversation
    }

    private func makeView(
        conversation: ZMConversation,
        selfUser: MockUserType? = nil
    ) -> UIView {
        let selfUser = selfUser ?? makeSelfUser()
        let headerView = GroupConversationHeaderView(
            conversation: conversation,
            selfUser: selfUser
        )
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let containerWidth: CGFloat = 375
        let container = UIView()
        container.backgroundColor = SemanticColors.View.backgroundConversationList
        container.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let size = container.systemLayoutSizeFitting(
            CGSize(width: containerWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: CGSize(width: containerWidth, height: size.height))
        return container
    }
}
