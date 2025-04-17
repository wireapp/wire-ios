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

    private var activityManager: MockBackgroundActivityManager!
    private var factory: BackgroundActivityFactory!

    private var account: Account {
        coreDataStack.account
    }

    override func setUp() {
        super.setUp()

        activityManager = MockBackgroundActivityManager()
        factory = BackgroundActivityFactory.shared
        factory.activityManager = activityManager
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

        return createSut(earService: earService)
    }

    override func tearDown() {
        factory = nil
        activityManager = nil
        try? sut.setEncryptionAtRest(enabled: false, skipMigration: true)

        super.tearDown()
    }

    private func setEncryptionAtRest(enabled: Bool, file: StaticString = #filePath, line: UInt = #line) {
        try? sut.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }
    
    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsEnabled() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        
        var session = try XCTUnwrap(sut)
        XCTAssertFalse(session.encryptMessagesAtRest)

        let expectedText = "Hello World"
        var groupConversation: ZMConversation!
        session.perform({
            let groupConversation = ModelHelper().createGroupConversation(in: session.managedObjectContext)
            try! groupConversation.appendText(content: expectedText)
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try session.setEncryptionAtRest(enabled: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(session.encryptMessagesAtRest)

        try session.unlockDatabase()
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
//    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsDisabled() throws {
//        // given
//        XCTAssertTrue(login())
//        var session = try XCTUnwrap(userSession)
//
//        let expectedText = "Hello World"
//
//        try session.setEncryptionAtRest(enabled: true, skipMigration: true)
//        XCTAssertTrue(session.encryptMessagesAtRest)
//
//        session.perform({
//            let groupConversation = self.conversation(for: self.groupConversation)
//            try! groupConversation?.appendText(content: expectedText)
//        })
//        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
//
//        // when
//        try session.setEncryptionAtRest(enabled: false)
//        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
//
//        // then
//        session = try XCTUnwrap(userSession)
//        XCTAssertFalse(session.encryptMessagesAtRest)
//
//        let groupConversation = self.conversation(for: self.groupConversation)
//        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
//        XCTAssertEqual(clientMessage?.messageText, expectedText)
//    }

}
