//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
@testable import WireSyncEngine

final class SessionManagerEncryptionAtRestMigrationTests: ZMUserSessionTestsBase {

    var userSessionDelegate: MockUserSessionDelegate!
    private var activityManager: MockBackgroundActivityManager!
    private var factory: BackgroundActivityFactory!
    private var setEncryptionAtRestExpectation: XCTestExpectation?

    private var account: Account {
        coreDataStack.account
    }

    private var userSession: ZMUserSession {
        sut
    }

    override func setUp() {
        userSessionDelegate = MockUserSessionDelegate()

        super.setUp()

        activityManager = MockBackgroundActivityManager()
        factory = BackgroundActivityFactory.shared
        factory.activityManager = activityManager
        setEncryptionAtRestExpectation = nil
    }

    /// This workaround is needed because all tests here are based on assumptions
    /// that the `managedObjectContext` is changed.
    /// To remove this workaround, delete this override  and the `mockEARService` should be used instead of
    /// a real instance of `EARService`.
    override func createSut() -> ZMUserSession {
        let earService = EARService(
            accountID: coreDataStack.account.userIdentifier,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext,
                coreDataStack.searchContext
            ],
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

        return session
    }

    override func tearDown() {
        factory = nil
        activityManager = nil

        try? sut.setEncryptionAtRest(enabled: false, skipMigration: true)

        super.tearDown()
        userSessionDelegate = nil
    }

    private func setEncryptionAtRest(enabled: Bool, file: StaticString = #filePath, line: UInt = #line) {
        try? sut.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

    private func login() {
        syncMOC.performAndWait {
            simulateLoggedInUser()
            ModelHelper().createSelfClient(in: syncMOC)
            syncMOC.saveOrRollback()
        }
        userSession.viewContext.saveOrRollback()
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsEnabled() throws {
        // given
        login()

        XCTAssertFalse(userSession.encryptMessagesAtRest)

        let expectedText = "Hello World"
        var groupConversation: ZMConversation!
        userSession.perform {
            groupConversation = ModelHelper().createGroupConversation(in: self.userSession.managedObjectContext)
            try! groupConversation.appendText(content: expectedText)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        setEncryptionAtRestExpectation = expectation(description: "wait for setEncryptionAtRest")
        try userSession.setEncryptionAtRest(enabled: true)
        self.wait(for: [setEncryptionAtRestExpectation!], timeout: 0.5)

        // then
        XCTAssertTrue(userSession.encryptMessagesAtRest)

        try userSession.unlockDatabase()
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsDisabled() throws {
        // given
        login()

        let expectedText = "Hello World"

        try userSession.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(userSession.encryptMessagesAtRest)

        var groupConversation: ZMConversation!
        userSession.perform {
            groupConversation = ModelHelper().createGroupConversation(in: self.userSession.managedObjectContext)
            try! groupConversation.appendText(content: expectedText)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        setEncryptionAtRestExpectation = expectation(description: "wait for setEncryptionAtRest")
        try userSession.setEncryptionAtRest(enabled: false)
        self.wait(for: [setEncryptionAtRestExpectation!], timeout: 0.5)

        // then
        XCTAssertFalse(userSession.encryptMessagesAtRest)

        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

}
