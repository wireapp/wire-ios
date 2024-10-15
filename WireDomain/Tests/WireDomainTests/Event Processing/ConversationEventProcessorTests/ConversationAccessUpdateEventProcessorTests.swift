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

import WireAPI
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import WireDomainSupport
import XCTest

final class ConversationAccessUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationAccessUpdateEventProcessor!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var repository: MockConversationRepositoryProtocol!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        repository = MockConversationRepositoryProtocol()

        sut = ConversationAccessUpdateEventProcessor(
            context: context,
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        repository = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Updates_Roles_And_Modes_No_Legacy_Role() async throws {
        // Given

        let event = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: [.invite, .link],
            accessRoles: [.teamMember],
            legacyAccessRole: nil /// no legacy role
        )

        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                in: context
            )
        }

        repository.fetchOrCreateConversationWithDomain_MockValue = conversation

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(repository.fetchOrCreateConversationWithDomain_Invocations.count, 1)
        internalTest_assertAccessRolesAndModes(
            for: conversation,
            expectedAccessModes: event.accessModes,
            expectedAccessRoles: event.accessRoles
        )
    }

    func testProcessEvent_It_Updates_Roles_Based_On_Legacy_Role() async throws {
        // Given

        let accessModes: Set<WireAPI.ConversationAccessMode> = [.invite, .link]

        let eventLegacyRoleActivated = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: accessModes,
            accessRoles: [],
            legacyAccessRole: .activated
        )

        let eventLegacyRoleNonActivated = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: accessModes,
            accessRoles: [],
            legacyAccessRole: .nonActivated
        )

        let eventLegacyRolePrivate = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: accessModes,
            accessRoles: [],
            legacyAccessRole: .private
        )

        let eventLegacyRoleTeam = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: accessModes,
            accessRoles: [],
            legacyAccessRole: .team
        )

        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                in: context
            )
        }

        repository.fetchOrCreateConversationWithDomain_MockValue = conversation

        // When legacy role == activated

        try await sut.processEvent(eventLegacyRoleActivated)
        internalTest_assertAccessRolesAndModes(
            for: conversation,
            expectedAccessModes: accessModes,
            expectedAccessRoles: [.teamMember, .nonTeamMember, .guest]
        )

        // When legacy role == non activated

        try await sut.processEvent(eventLegacyRoleNonActivated)
        internalTest_assertAccessRolesAndModes(
            for: conversation,
            expectedAccessModes: accessModes,
            expectedAccessRoles: [.teamMember, .nonTeamMember, .guest, .service]
        )

        // When legacy role == private

        try await sut.processEvent(eventLegacyRolePrivate)
        internalTest_assertAccessRolesAndModes(
            for: conversation,
            expectedAccessModes: accessModes,
            expectedAccessRoles: []
        )

        // When legacy role == team

        try await sut.processEvent(eventLegacyRoleTeam)
        internalTest_assertAccessRolesAndModes(
            for: conversation,
            expectedAccessModes: accessModes,
            expectedAccessRoles: [.teamMember]
        )
    }

    private func internalTest_assertAccessRolesAndModes(
        for conversation: ZMConversation,
        expectedAccessModes: Set<WireAPI.ConversationAccessMode>,
        expectedAccessRoles: Set<WireAPI.ConversationAccessRole>
    ) {
        // Then

        XCTAssertEqual(conversation.accessModeStrings?.sorted(), expectedAccessModes.map(\.rawValue).sorted())
        XCTAssertEqual(conversation.accessRoleStringsV2?.sorted(), expectedAccessRoles.map(\.rawValue).sorted())
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let conversationID = ConversationID(uuid: id, domain: domain)
        static let senderID = UserID(uuid: id, domain: domain)
    }

}
