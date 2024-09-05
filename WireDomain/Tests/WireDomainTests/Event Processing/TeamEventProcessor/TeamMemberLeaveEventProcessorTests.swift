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

import Foundation
import WireAPI
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class TeamMemberLeaveEventProcessorTests: XCTestCase {

    var sut: TeamMemberLeaveEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = TeamMemberLeaveEventProcessor(
            context: context
        )
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testProcessEvent_It_Deletes_A_Member_When_Receiving_A_Team_Member_Leave_Update_Event_For_Another_User() async throws {
        // Given

        await context.perform { [context] in
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = Scaffolding.userID

            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = Scaffolding.teamID

            let member = Member.getOrUpdateMember(
                for: user,
                in: team,
                context: context
            )

            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            XCTAssertNotNil(ZMUser.fetch(with: Scaffolding.userID, in: context))

            /// users won't be deleted as we might be in other (non-team) conversations with them
            let team = try XCTUnwrap(Team.fetch(with: Scaffolding.teamID, in: context), "No team")

            XCTAssertEqual(team.members, [])
        }
    }

    func testProcessEvent_It_Request_Account_Deletion_When_Receiving_A_Team_Member_Leave_Update_Event_For_Self_User() async throws {
        // Given

        await context.perform { [context] in
            let user = ZMUser.selfUser(in: context)
            user.remoteIdentifier = Scaffolding.userID

            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = Scaffolding.teamID

            let member = Member.getOrUpdateMember(
                for: user,
                in: team,
                context: context
            )

            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        let expectation = XCTestExpectation()
        let notificationName = AccountDeletedNotification.notificationName

        NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: nil
        ) { notification in

            XCTAssertNotNil(notification.userInfo?[notificationName] as? AccountDeletedNotification)

            // Then

            expectation.fulfill()
        }

        // When

        try await sut.processEvent(Scaffolding.event)
    }

    func testProcessEvent_It_Removes_A_Member_From_All_Group_Conversations_They_Were_Part_Of_When_Receiving_A_Member_Leave_Event_For_That_Member() async throws {
        // Given

        await context.perform { [context] in
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = Scaffolding.userID

            let otherUser = ZMUser.insertNewObject(in: context)
            otherUser.remoteIdentifier = UUID()

            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = Scaffolding.teamID

            let teamConversation1 = ZMConversation.insertNewObject(in: context)
            teamConversation1.remoteIdentifier = Scaffolding.teamConversationID
            teamConversation1.conversationType = .group
            teamConversation1.addParticipantAndUpdateConversationState(
                user: user,
                role: nil
            )
            teamConversation1.team = team

            let conversation = ZMConversation.insertGroupConversation(
                moc: context,
                participants: [user, otherUser]
            )

            conversation?.remoteIdentifier = Scaffolding.conversationID

            let member = Member.getOrUpdateMember(
                for: user,
                in: team,
                context: context
            )

            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let user = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context), "No User")

            XCTAssertNotNil(Team.fetch(with: Scaffolding.teamID, in: context), "No User")
            XCTAssertNil(user.membership)

            let teamConversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.teamConversationID, in: context), "No Team Conversation")

            let conversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.conversationID, in: context), "No Conversation")

            XCTAssertFalse(teamConversation.localParticipants.contains(user))
            XCTAssertFalse(conversation.localParticipants.contains(user))
        }
    }

    func testProcessEvent_It_Appends_A_System_Message_To_All_Team_Conversations_They_Were_Part_Of_When_Receiving_A_Member_Leave_Event_For_That_Member() async throws {
        // Given

        await context.perform { [context] in
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = Scaffolding.userID

            let otherUser = ZMUser.insertNewObject(in: context)
            otherUser.remoteIdentifier = UUID()

            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = Scaffolding.teamID

            let teamConversation1 = ZMConversation.insertNewObject(in: context)
            teamConversation1.remoteIdentifier = Scaffolding.teamConversationID
            teamConversation1.conversationType = .group
            teamConversation1.addParticipantAndUpdateConversationState(user: user, role: nil)
            teamConversation1.team = team

            let teamConversation2 = ZMConversation.insertNewObject(in: context)
            teamConversation2.remoteIdentifier = Scaffolding.anotherTeamConversationID
            teamConversation2.conversationType = .group
            teamConversation2.addParticipantAndUpdateConversationState(user: user, role: nil)
            teamConversation2.team = team

            let conversation = ZMConversation.insertGroupConversation(
                moc: context,
                participants: [user, otherUser]
            )
            conversation?.remoteIdentifier = Scaffolding.conversationID

            let member = Member.getOrUpdateMember(
                for: user,
                in: team,
                context: context
            )

            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        let timestamp = Scaffolding.date(from: Scaffolding.time)

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [self] in

            let user = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context), "No User")
            XCTAssertNotNil(Team.fetch(with: Scaffolding.teamID, in: context))
            XCTAssertNil(user.membership)

            let teamConversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.teamConversationID, in: context), "No Team Conversation")

            let teamAnotherConversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.anotherTeamConversationID, in: context), "No Team Conversation")

            let conversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.conversationID, in: context), "No Conversation")

            try checkLastMessage(
                in: teamConversation,
                isLeaveMessageFor: user,
                at: timestamp
            )

            try checkLastMessage(
                in: teamAnotherConversation,
                isLeaveMessageFor: user,
                at: timestamp
            )

            let lastMessage = try XCTUnwrap(conversation.lastMessage as? ZMSystemMessage)
            XCTAssertNotEqual(lastMessage.systemMessageType, .teamMemberLeave, "Should not append leave message to regular conversation")
        }
    }

    private func checkLastMessage(
        in conversation: ZMConversation,
        isLeaveMessageFor user: ZMUser,
        at timestamp: Date
    ) throws {
        let lastMessage = try XCTUnwrap(conversation.lastMessage as? ZMSystemMessage, "Last message is not system message")

        XCTAssertEqual(lastMessage.systemMessageType, .teamMemberLeave, "System message is not teamMemberLeave: but '\(lastMessage.systemMessageType.rawValue)")

        let serverTimeStamp = try XCTUnwrap(lastMessage.serverTimestamp, "System message should have timestamp")

        XCTAssertEqual(
            serverTimeStamp.timeIntervalSince1970,
            timestamp.timeIntervalSince1970,
            accuracy: 0.1
        )
    }
}

// MARK: - Scaffolding

private enum Scaffolding {

    static let teamID = UUID()
    static let userID = UUID()
    static let time = "2021-05-12T10:52:02.671Z"
    static let teamConversationID = UUID()
    static let anotherTeamConversationID = UUID()
    static let conversationID = UUID()

    static func date(from string: String) -> Date {
        ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
    }

    static let event = TeamMemberLeaveEvent(
        time: date(from: time),
        teamID: teamID,
        userID: userID
    )

}

private extension ISO8601DateFormatter {
    static let fractionalInternetDateTime = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }()
}
