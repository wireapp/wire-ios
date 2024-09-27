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

import WireSyncEngine
import WireTransport
import XCTest
@testable import Wire

final class AppStateCalculatorTests: XCTestCase {
    private var sut: AppStateCalculator!
    private var delegate: MockAppStateCalculatorDelegate!

    override func setUp() {
        super.setUp()

        sut = AppStateCalculator()
        delegate = MockAppStateCalculatorDelegate()
        delegate.appStateCalculatorDidCalculateCompletion_MockMethod = { _, _, completion in
            completion()
        }
        sut.delegate = delegate
    }

    override func tearDown() {
        sut = nil
        delegate = nil

        super.tearDown()
    }

    // MARK: - Tests AppState Cases

    func testThatAppStateChanges_OnDidBlacklistCurrentVersion() {
        // WHEN
        sut.applicationDidBecomeActive()
        sut.sessionManagerDidBlacklistCurrentVersion(reason: .appVersionBlacklisted)

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted(reason: .appVersionBlacklisted))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidJailbreakCurrentVersion() {
        // WHEN
        sut.applicationDidBecomeActive()
        sut.sessionManagerDidBlacklistJailbrokenDevice()

        // THEN
        XCTAssertEqual(sut.appState, .jailbroken)
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidFailToLoadDatabase() {
        enum DBError: Error {
            case migrationError
        }

        // WHEN
        sut.applicationDidBecomeActive()
        sut.sessionManagerDidFailToLoadDatabase(error: DBError.migrationError)

        // THEN
        XCTAssertEqual(sut.appState, .databaseFailure(reason: DBError.migrationError))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnRetryStart() {
        // WHEN
        sut.applicationDidBecomeActive()
        sut.sessionManagerAsksToRetryStart()

        // THEN
        XCTAssertEqual(sut.appState, .retryStart)
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnWillMigrateAccount() {
        // GIVEN
        let account = Account(userName: "dummy", userIdentifier: UUID())
        let selectedAccount = Account(userName: "selectedDummy", userIdentifier: UUID())
        sut.testHelper_setAppState(.loading(account: account, from: selectedAccount))
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerWillMigrateAccount(userSessionCanBeTornDown: {})

        // THEN
        XCTAssertEqual(sut.appState, .migrating)
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnSessionManagerWillLogout() {
        // GIVEN
        let error = NSError(userSessionErrorCode: UserSessionErrorCode.unknownError, userInfo: nil)
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: nil)

        // THEN
        XCTAssertEqual(sut.appState, .unauthenticated(error: error))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidFailToLogin() {
        // GIVEN
        let error = NSError(userSessionErrorCode: UserSessionErrorCode.invalidCredentials, userInfo: nil)
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidFailToLogin(error: error)

        // THEN
        XCTAssertEqual(sut.appState, .unauthenticated(error: error))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidFailToLogin_CanNotRegisterMoreClients() {
        // GIVEN
        let error = NSError(userSessionErrorCode: UserSessionErrorCode.canNotRegisterMoreClients, userInfo: nil)
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidFailToLogin(error: error)

        // THEN
        XCTAssertEqual(sut.appState, .unauthenticated(error: error))
    }

    func testThatAppStateChanges_OnSessionLockChange() {
        // GIVEN
        let userSession = UserSessionMock()
        userSession.isLocked = true
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidReportLockChange(forSession: userSession)

        // THEN
        XCTAssertEqual(sut.appState, .locked(userSession))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnUserAuthenticationDidComplete() {
        // GIVEN
        let userSession = UserSessionMock()
        sut.applicationDidBecomeActive()

        // WHEN
        sut.userAuthenticationDidComplete(
            userSession: userSession
        )

        // THEN
        XCTAssertEqual(sut.appState, .authenticated(userSession))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidPerformFederationMigration_authenticated() {
        testThatAppStateChanges_OnDidPerformFederationMigration(authenticated: true)
    }

    func testThatAppStateChanges_OnDidPerformFederationMigration_unauthenticated() {
        testThatAppStateChanges_OnDidPerformFederationMigration(authenticated: false)
    }

    func testThatAppStateChanges_OnDidPerformFederationMigration(
        authenticated: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // GIVEN
        let userSession = authenticated ? UserSessionMock() : nil
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidPerformFederationMigration(activeSession: userSession)

        // THEN
        if let userSession {
            XCTAssertEqual(sut.appState, .authenticated(userSession))
        } else {
            guard case let .unauthenticated(error: error) = sut.appState else {
                return XCTFail("Error - unauthenticated")
            }

            XCTAssertEqual(error?.userSessionErrorCode, .needsAuthenticationAfterMigration)
        }
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnDidCompleteInitialSync() {
        // GIVEN
        let userSession = UserSessionMock()
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidCompleteInitialSync(for: userSession)

        // THEN
        XCTAssertEqual(sut.appState, .authenticated(userSession))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatAppStateChanges_OnWillEnrollCertificate() {
        // GIVEN
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerRequireCertificateEnrollment()

        // THEN
        XCTAssertEqual(sut.appState, .certificateEnrollmentRequired)
    }

    func testThatAppStateChanges_OnDidUpdateCertificate() {
        // GIVEN
        let userSession = UserSessionMock()
        sut.applicationDidBecomeActive()

        // WHEN
        sut.sessionManagerDidEnrollCertificate(for: userSession)

        // THEN
        XCTAssertEqual(sut.appState, .authenticated(userSession))
    }

    // MARK: - Tests AppState Changes

    func testApplicationDontTransit_WhenAppStateDontChanges() {
        // GIVEN
        sut.applicationDidBecomeActive()
        sut.testHelper_setAppState(.blacklisted(reason: .appVersionBlacklisted))

        // WHEN
        sut.sessionManagerDidBlacklistCurrentVersion(reason: .appVersionBlacklisted)

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted(reason: .appVersionBlacklisted))
        XCTAssertTrue(delegate.appStateCalculatorDidCalculateCompletion_Invocations.isEmpty)
    }

    // Quarantined
    func testApplicationTransit_WhenAppStateChanges() {
        // GIVEN
        let userSession = UserSessionMock()
        userSession.isLocked = true
        sut.applicationDidBecomeActive()
        sut.testHelper_setAppState(.blacklisted(reason: .appVersionBlacklisted))

        // WHEN
        sut.sessionManagerDidReportLockChange(forSession: userSession)

        // THEN
        XCTAssertEqual(sut.appState, .locked(userSession))
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    // MARK: - Tests When App Become Active

    func testThatAppStateDoesntChange_OnDidReportLockChange_BeforeAppBecomeActive() {
        // GIVEN
        let userSession = UserSessionMock()
        userSession.isLocked = true
        sut.applicationDidEnterBackground()

        // WHEN
        sut.sessionManagerDidReportLockChange(forSession: userSession)

        // THEN
        XCTAssertTrue(delegate.appStateCalculatorDidCalculateCompletion_Invocations.isEmpty)
    }

    func testThatAppStateChanges_OnDidReportLockChange_AfterAppHasBecomeActive() {
        // GIVEN
        let userSession = UserSessionMock()
        userSession.isLocked = true
        sut.applicationDidEnterBackground()
        sut.sessionManagerDidReportLockChange(forSession: userSession)

        // WHEN
        sut.applicationDidBecomeActive()

        // THEN
        XCTAssertEqual(delegate.appStateCalculatorDidCalculateCompletion_Invocations.count, 1)
    }

    func testThatItDoesntTransitionAwayFromBlacklisted_IfThereIsNoCurrentAPIVersion() {
        // GIVEN
        let userSession = UserSessionMock()
        sut.applicationDidBecomeActive()
        BackendInfo.apiVersion = nil

        let blacklistState = AppState.blacklisted(reason: .clientAPIVersionObsolete)
        sut.testHelper_setAppState(blacklistState)

        // WHEN
        sut.sessionManagerDidReportLockChange(forSession: userSession)

        // THEN
        XCTAssertEqual(sut.appState, blacklistState)
    }
}
