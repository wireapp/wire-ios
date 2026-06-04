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
import WireDataModelSupport
import XCTest
@testable import WireDomain

final class ResetProteusSessionUseCaseTests: XCTestCase {

    private var sut: ResetProteusSessionUseCase!
    private var proteusService: MockProteusServiceInterface!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        proteusService = MockProteusServiceInterface()

        sut = ResetProteusSessionUseCase(
            syncContext: context,
            proteusService: proteusService
        )
    }

    override func tearDown() async throws {
        sut = nil
        proteusService = nil
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testInvoke_DeletesProteusSessionAndMarksClientForNotification() async throws {
        // Given a client with a session and no one-to-one conversation to notify.
        proteusService.deleteSessionId_MockMethod = { _ in }

        let (userClient, sessionID) = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)
            let client = modelHelper.createClient(for: user)
            return (client, client.proteusSessionID)
        }
        let expectedSessionID = try XCTUnwrap(sessionID)

        // When
        await sut.invoke(userClient: userClient)

        // Then the local session is deleted...
        XCTAssertEqual(proteusService.deleteSessionId_Invocations, [expectedSessionID])

        // ...and the client is marked so the other party gets notified.
        let needsToNotify = await context.perform { userClient.needsToNotifyOtherUserAboutSessionReset }
        XCTAssertTrue(needsToNotify)
    }

    func testInvoke_GivenSessionDeletionFails_StillMarksClientForNotification() async throws {
        // Given the proteus session deletion fails.
        proteusService.deleteSessionId_MockError = ProteusServiceError.failedToDeleteSession

        let userClient = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)
            return modelHelper.createClient(for: user)
        }

        // When
        await sut.invoke(userClient: userClient)

        // Then the client is still marked for notification despite the deletion failure.
        let needsToNotify = await context.perform { userClient.needsToNotifyOtherUserAboutSessionReset }
        XCTAssertTrue(needsToNotify)
    }
}

private enum ProteusServiceError: Error {
    case failedToDeleteSession
}
