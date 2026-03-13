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

final class ZMUserSessionTests_EncryptionAtRest: ZMUserSessionTestsBase {

    private var activityManager: MockBackgroundActivityManager!
    private var factory: BackgroundActivityFactory!
    private var earService: EARService!
    private let earServiceFactory: EARServiceFactory = .init()

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
        let earService = earServiceFactory.createEARService(
            accountID: coreDataStack.account.userIdentifier,
            coreDataStack: coreDataStack,
            canPerformKeyMigration: true,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: MockAuthenticationContextProtocol()
        )

        self.earService = earService

        return createSut(earService: earService)
    }

    override func tearDown() {
        earService = nil
        factory = nil
        activityManager = nil
        try? sut.setEncryptionAtRest(enabled: false, skipMigration: true)

        super.tearDown()
    }

    private func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) async throws {
        try await uiMOC.perform { [sut] in
            try sut.setEncryptionAtRest(enabled: enabled, skipMigration: skipMigration)
        }
    }

    private func setupDatabaseContexts() async {
        await earServiceFactory.setupDatabaseContexts(
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext
            ],
            onEARService: earService
        )
    }

    private func isDatabaseLocked() async -> Bool {
        await uiMOC.perform { [sut] in
            sut.isDatabaseLocked
        }
    }

    // MARK: - Database migration

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsEnabled() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
        try await setEncryptionAtRest(enabled: true, skipMigration: false)

        // then
        XCTAssertEqual(userSessionDelegate.prepareForMigration_Invocations, [account])
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsDisabled() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
        try await setEncryptionAtRest(enabled: false, skipMigration: false)

        // then
        XCTAssertEqual(userSessionDelegate.prepareForMigration_Invocations, [account])
    }

    // MARK: - Database locking/unlocking

    func testThatDatabaseIsUnlocked_WhenEncryptionAtRestIsDisabled() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        // when
        try await setEncryptionAtRest(enabled: false, skipMigration: true)

        // then
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)
    }

    func testThatDatabaseIsUnlocked_AfterActivatingEncryptionAtRest() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        // when
        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // then
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)
    }

    func testThatDatabaseIsUnlocked_AfterDeactivatingEncryptionAtRest() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // when
        try await setEncryptionAtRest(enabled: false, skipMigration: true)

        // then
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)
    }

    @MainActor
    func testThatDatabaseIsUnlocked_AfterUnlockingDatabase() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)
        sut.applicationDidEnterBackground(nil)

        // when
        try sut.unlockDatabase()

        // then
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatDatabaseIsLocked_AfterEnteringBackground() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // when
        sut.applicationDidEnterBackground(nil)

        // then
        let locked = await isDatabaseLocked()
        XCTAssertTrue(locked)
    }

    @MainActor
    func testThatDatabaseIsLocked_AfterBackgroundTaskCompletesInTheBackground() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // when
        let activity = factory.startBackgroundActivity(name: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        factory.endBackgroundActivity(activity)

        // then
        let locked = await isDatabaseLocked()
        XCTAssertTrue(locked)
    }

    @MainActor
    func testThatDatabaseIsNotLocked_IfThereIsAnActiveBackgroundTask() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // when
        let activity = factory.startBackgroundActivity(name: "Activity 1")!
        application.simulateApplicationDidEnterBackground()

        // then
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)
        factory.endBackgroundActivity(activity)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatDatabaseIsLocked_WhenTheCustomTimeoutHasExpiredInTheBackground() async throws {
        // given
        factory.backgroundTaskTimeout = 2
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        let earMessageEncryptionService = try await uiMOC.perform { [uiMOC] in
            try uiMOC.getEarMessageEncryptionService()
        }

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // when
        let expectation = XCTestExpectation(description: "The expiration handler is called")
        _ = factory.startBackgroundActivity(name: "Activity 1", expirationHandler: {
            expectation.fulfill()
        })!
        application.simulateApplicationDidEnterBackground()
        XCTAssertNotNil(earMessageEncryptionService.getDatabaseKey())

        await fulfillment(of: [expectation], timeout: 4)

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
        XCTAssertNil(earMessageEncryptionService.getDatabaseKey())
    }

    // MARK: - Database lock handler/observer

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatDatabaseLockedHandlerIsCalled_AfterDatabaseIsLocked() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // expect
        let databaseIsLocked = XCTestExpectation(description: "database is locked")
        var token: Any? = sut.registerDatabaseLockedHandler { isDatabaseLocked in
            if isDatabaseLocked {
                databaseIsLocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        sut.applicationDidEnterBackground(nil)
        await fulfillment(of: [databaseIsLocked], timeout: 0.5)

        // cleanup
        token = nil
    }

    @MainActor
    func testThatDatabaseLockedHandlerIsCalled_AfterUnlockingDatabase() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)
        sut.applicationDidEnterBackground(nil)

        // expect
        let databaseIsUnlocked = XCTestExpectation(description: "database is unlocked")
        var token: Any? = sut.registerDatabaseLockedHandler { isDatabaseLocked in
            if !isDatabaseLocked {
                databaseIsUnlocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        try sut.unlockDatabase()
        await fulfillment(of: [databaseIsUnlocked], timeout: 0.5)

        // cleanup
        token = nil
    }

    // MARK: - Misc

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    @MainActor
    func testThatIfDatabaseIsLocked_ThenUserSessionLockIsSet() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: true, skipMigration: true)

        // expect
        let databaseIsLocked = XCTestExpectation(description: "isDatabaseLocked becomes true")
        var token: Any? = sut.registerDatabaseLockedHandler { isDatabaseLocked in
            if isDatabaseLocked {
                databaseIsLocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        sut.applicationDidEnterBackground(nil)
        await fulfillment(of: [databaseIsLocked], timeout: 0.5)

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
        XCTAssertEqual(sut.lock, .database)

        // cleanup
        token = nil
    }

    @MainActor
    func testThatIfDatabaseIsNotLocked_ThenUserSessionLockIsNotSet() async throws {
        // given
        await setupDatabaseContexts()
        await simulateLoggedInUser()

        try await setEncryptionAtRest(enabled: false, skipMigration: true)
        let locked = await isDatabaseLocked()
        XCTAssertFalse(locked)

        // then
        XCTAssertNotEqual(sut.lock, .database)
    }

}
