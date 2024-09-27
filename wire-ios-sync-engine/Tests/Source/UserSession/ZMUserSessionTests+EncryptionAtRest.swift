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
import LocalAuthentication
import WireDataModelSupport
@testable import WireSyncEngine

// MARK: - MockUserSessionDelegate

final class MockUserSessionDelegate: NSObject, UserSessionDelegate {
    var prepareForMigration_Invocations = [Account]()
    func prepareForMigration(
        for account: WireDataModel.Account,
        onReady: @escaping (NSManagedObjectContext) throws -> Void
    ) {
        prepareForMigration_Invocations.append(account)
    }

    func userSessionDidUnlock(_: ZMUserSession) {}

    func clientRegistrationDidSucceed(accountId: UUID) {}

    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {}

    func clientCompletedInitialSync(accountId: UUID) {}

    var calleduserDidLogout: (Bool, UUID)?
    func userDidLogout(accountId: UUID) {
        calleduserDidLogout = (true, accountId)
    }

    func authenticationInvalidated(_ error: NSError, accountId: UUID) {}
}

// MARK: - ZMUserSessionTests_EncryptionAtRest

final class ZMUserSessionTests_EncryptionAtRest: ZMUserSessionTestsBase {
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
                coreDataStack.searchContext,
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

    private func setEncryptionAtRest(enabled: Bool, file: StaticString = #file, line: UInt = #line) {
        try? sut.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

    // MARK: - Database migration

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsEnabled() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
        try sut.setEncryptionAtRest(enabled: true)

        // then
        XCTAssertEqual(userSessionDelegate.prepareForMigration_Invocations, [account])
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsDisabled() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
        try sut.setEncryptionAtRest(enabled: false)

        // then
        XCTAssertEqual(userSessionDelegate.prepareForMigration_Invocations, [account])
    }

    // MARK: - Database locking/unlocking

    func testThatDatabaseIsUnlocked_WhenEncryptionAtRestIsDisabled() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }

        // when
        setEncryptionAtRest(enabled: false)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterActivatingEncryptionAtRest() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }

        // when
        setEncryptionAtRest(enabled: true)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterDeactivatingEncryptionAtRest() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // when
        setEncryptionAtRest(enabled: false)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterUnlockingDatabase() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try sut.unlockDatabase()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsLocked_AfterEnteringBackground() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // when
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsLocked_AfterBackgroundTaskCompletesInTheBackground() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // when
        let activity = factory.startBackgroundActivity(name: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        factory.endBackgroundActivity(activity)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsNotLocked_IfThereIsAnActiveBackgroundTask() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // when
        let activity = factory.startBackgroundActivity(name: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
        factory.endBackgroundActivity(activity)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsLocked_WhenTheCustomTimeoutHasExpiredInTheBackground() throws {
        // given
        factory.backgroundTaskTimeout = 2
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // when
        _ = factory.startBackgroundActivity(name: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        XCTAssertNotNil(sut.managedObjectContext.databaseKey)

        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "The expiration handler is called.")], timeout: 4.0)

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
        XCTAssertNil(sut.managedObjectContext.databaseKey)
    }

    // MARK: - Database lock handler/observer

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseLockedHandlerIsCalled_AfterDatabaseIsLocked() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        // expect
        let databaseIsLocked = customExpectation(description: "database is locked")
        var token: Any? = sut.registerDatabaseLockedHandler { isDatabaseLocked in
            if isDatabaseLocked {
                databaseIsLocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // cleanup
        token = nil
    }

    func testThatDatabaseLockedHandlerIsCalled_AfterUnlockingDatabase() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // expect
        let databaseIsUnlocked = customExpectation(description: "database is unlocked")
        var token: Any? = sut.registerDatabaseLockedHandler { isDatabaseLocked in
            if !isDatabaseLocked {
                databaseIsUnlocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        try sut.unlockDatabase()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // cleanup
        token = nil
    }

    // MARK: - Misc

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatIfDatabaseIsLocked_ThenUserSessionLockIsSet() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: true)

        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(sut.isDatabaseLocked)

        // then
        XCTAssertEqual(sut.lock, .database)
    }

    func testThatIfDatabaseIsNotLocked_ThenUserSessionLockIsNotSet() throws {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            syncMOC.saveOrRollback()
        }
        setEncryptionAtRest(enabled: false)
        XCTAssertFalse(sut.isDatabaseLocked)

        // then
        XCTAssertNotEqual(sut.lock, .database)
    }
}
