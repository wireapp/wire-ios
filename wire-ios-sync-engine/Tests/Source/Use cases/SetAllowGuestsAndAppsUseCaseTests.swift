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

import WireDataModelSupport
import WireNetworkSupport
import XCTest

@testable import WireSyncEngine

final class SetAllowGuestsAndAppsUseCaseTests: XCTestCase {

    // MARK: - Properties

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()
    private var mockConversation: ZMConversation!
    private var mockSelfUser: ZMUser!
    private var sut: SetAllowGuestAndAppsUseCaseProtocol!

    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - setUp

    override func setUp() async throws {
        stack = try await coreDataStackHelper.createStack()
        await syncContext.perform { [self] in
            sut = SetAllowGuestAndAppsUseCase()
            mockSelfUser = modelHelper.createSelfUser(in: syncContext)
            mockConversation = modelHelper.createGroupConversation(in: syncContext)
            mockConversation.teamRemoteIdentifier = UUID()
        }
    }

    // MARK: - tearDown

    override func tearDown() async throws {
        stack = nil
        sut = nil
        mockSelfUser = nil
        mockConversation = nil
        try coreDataStackHelper.cleanupDirectory()
    }

    // MARK: - Helper method

    private func setUpRoleAndAction() {
        let role = Role.insertNewObject(in: syncContext)
        let action = Action.insertNewObject(in: syncContext)
        action.name = "modify_conversation_access"
        role.actions = [action]

        mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)
    }

    // MARK: Unit Tests

    func testGuestEnablementSucceeds() async throws {

        // GIVEN
        await syncContext.perform { [self] in
            setUpRoleAndAction()
        }

        // WHEN
        try await sut.invoke(conversation: mockConversation, allowGuests: true, allowApps: false)

    }

    func testGuestEnablementFails_WithInsufficientPermissions() async {

        // WHEN
        do {
            try await sut.invoke(conversation: mockConversation, allowGuests: true, allowApps: false)
            XCTFail("Expected operation to fail, but it succeeded.")
        } catch {
            guard case .invalidOperation = error as? SetAllowGuestsAndAppsUseCaseError else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

    }

    func testAppsEnablementSucceeds() async throws {

        // GIVEN
        await syncContext.perform { [self] in
            setUpRoleAndAction()
        }

        // WHEN
        try await sut.invoke(conversation: mockConversation, allowGuests: false, allowApps: true)

    }

    func testAppsEnablementFails_WithInsufficientPermissions() async {

        // WHEN
        do {
            try await sut.invoke(conversation: mockConversation, allowGuests: false, allowApps: true)
            XCTFail("Expected operation to fail, but it succeeded.")
        } catch {
            guard case .invalidOperation = error as? SetAllowGuestsAndAppsUseCaseError else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

    }

}
