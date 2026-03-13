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

import Foundation
import LocalAuthentication
import WireDataModelSupport
@testable @preconcurrency import WireSyncEngine

final class SessionManagerEncryptionAtRestMigrationTests: ZMUserSessionTestsBase {

    var userSessionDelegate: MockUserSessionDelegate!
    private var setEncryptionAtRestExpectation: XCTestExpectation?
    private var earService: EARService!

    private var account: Account {
        coreDataStack.account
    }

    override func setUp() {
        userSessionDelegate = MockUserSessionDelegate()

        super.setUp()

        setEncryptionAtRestExpectation = nil
    }

    /// This workaround is needed because all tests here are based on assumptions
    /// that the `managedObjectContext` is changed.
    /// To remove this workaround, delete this override  and the `mockEARService` should be used instead of
    /// a real instance of `EARService`.
    override func createSut() -> ZMUserSession {
        let earService = EARService(
            accountID: coreDataStack.account.userIdentifier,
            coreDataStack: coreDataStack,
            canPerformKeyMigration: true,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: MockAuthenticationContextProtocol()
        )

        let session = createSut(earService: earService)

        session.delegate = userSessionDelegate
        userSessionDelegate.prepareForMigrationOnReadyMockMethod = { _, onReady in
            try onReady(self.uiMOC)
            self.setEncryptionAtRestExpectation?.fulfill()
        }

        self.earService = earService

        return session
    }

    override func tearDown() {
        try? sut.setEncryptionAtRest(enabled: false, skipMigration: true)

        super.tearDown()
        userSessionDelegate = nil
        earService = nil
    }

    private func setupDatabaseContexts() async {
        await earService.setupDatabaseContexts(
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext
            ]
        )
    }

    private func login() async {
        await simulateLoggedInUser()

        await syncMOC.perform { [syncMOC] in
            ModelHelper().createSelfClient(in: syncMOC)
            syncMOC.saveOrRollback()
        }
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsEnabled() async throws {
        // given
        await setupDatabaseContexts()
        await login()

        XCTAssertFalse(sut.encryptMessagesAtRest)

        let expectedText = "Hello World"
        let groupConversation = try await uiMOC.perform { [uiMOC] in
            let groupConversation = ModelHelper().createGroupConversation(in: uiMOC)
            try groupConversation.appendText(content: expectedText)
            return groupConversation
        }

        // when
        setEncryptionAtRestExpectation = expectation(description: "wait for setEncryptionAtRest")
        try sut.setEncryptionAtRest(enabled: true)
        await fulfillment(of: [setEncryptionAtRestExpectation!], timeout: 0.5)

        // then
        XCTAssertTrue(sut.encryptMessagesAtRest)

        try sut.unlockDatabase()
        let clientMessage = groupConversation.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsDisabled() async throws {
        // given
        await setupDatabaseContexts()
        await login()

        let expectedText = "Hello World"

        try sut.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(sut.encryptMessagesAtRest)

        let groupConversation = try await uiMOC.perform { [uiMOC] in
            let groupConversation = ModelHelper().createGroupConversation(in: uiMOC)
            try groupConversation.appendText(content: expectedText)
            return groupConversation
        }

        // when
        setEncryptionAtRestExpectation = expectation(description: "wait for setEncryptionAtRest")
        try sut.setEncryptionAtRest(enabled: false)
        await fulfillment(of: [setEncryptionAtRestExpectation!], timeout: 0.5)

        // then
        XCTAssertFalse(sut.encryptMessagesAtRest)

        let clientMessage = groupConversation.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

}
