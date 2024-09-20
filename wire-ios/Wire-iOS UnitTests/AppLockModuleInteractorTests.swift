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
@testable import Wire
import XCTest

final class AppLockModuleInteractorTests: XCTestCase {

    private var sut: AppLockModule.Interactor!
    private var presenter: AppLockModule.MockPresenter!
    private var session: UserSessionMock!
    private var appLock: AppLockModule.MockAppLockController!
    private var authenticationType: AppLockModule.MockAuthenticationTypeDetector!
    private var applicationStateProvider: AppLockModule.MockApplicationStateProvider!

    override func setUp() {
        super.setUp()
        presenter = .init()
        session = UserSessionMock()
        appLock = .init()
        authenticationType = .init()
        applicationStateProvider = .init()

        sut = .init(
            userSession: session,
            authenticationType: authenticationType,
            applicationStateProvider: applicationStateProvider
        )

        sut.presenter = presenter
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        session = nil
        appLock = nil
        authenticationType = nil
        applicationStateProvider = nil
        super.tearDown()
    }

    // MARK: - Initiate authentication

    func test_InitiateAuthentication_NeedsToCreateCustomPasscode_Required() {
        // Given
        session.isCustomAppLockPasscodeSet = false
        session.requireCustomAppLockPasscode = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_InitiaAuthentication_NeedsToCreateCustomPasscode_NotRequired() {
        // Given
        session.isCustomAppLockPasscodeSet = false
        session.requireCustomAppLockPasscode = false
        authenticationType.current = .unavailable

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_InitiaAuthentication_NeedsToCreatePasscode_InformingUserOfConfigChange() {
        // Given
        session.isCustomAppLockPasscodeSet = false
        session.requireCustomAppLockPasscode = true
        session.needsToNotifyUserOfAppLockConfiguration = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: true)])
    }

    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode() {
        // Given
        session.isCustomAppLockPasscodeSet = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode_InformingUserOfConfigChange() {
        // Given
        session.isCustomAppLockPasscodeSet = true
        session.needsToNotifyUserOfAppLockConfiguration = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: true)])
    }

    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode_WhenDatabaseIsLocked() {
        // Given
        session.lock = .database
        session.isCustomAppLockPasscodeSet = false
        authenticationType.current = .unavailable

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    func test_InitiateAuthentication_SessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: false))

        // Then
        XCTAssertEqual(session.evaluateAuthentication.count, 0)
        XCTAssertEqual(session.openApp.count, 1)
    }

    func test_InitiateAuthentication_RequireForegroundApp_ReturnsNothingIfAppIsInBackground() {
        // Given
        applicationStateProvider.applicationState = .background
        session.isCustomAppLockPasscodeSet = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: true))

        // Then
        XCTAssertEqual(presenter.results, [])
    }

    func test_InitiateAuthentication_NeedsToCreateCustomPasscodeAndRequireForegroundApp_ReturnsNothingIfAppIsInBackground() {
        // Given
        applicationStateProvider.applicationState = .background
        session.isCustomAppLockPasscodeSet = false
        session.requireCustomAppLockPasscode = true

        // When
        sut.executeRequest(.initiateAuthentication(requireForegroundApp: true))

        // Then
        XCTAssertEqual(presenter.results, [])
    }

    // MARK: - Evaluate authentication

    func test_EvaluateAuthentication_SessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.evaluateAuthentication.count, 0)
        XCTAssertEqual(session.openApp.count, 1)
    }

    func test_EvaluateAuthentication_ScreenLock() {
        // Given
        session.lock = .screen
        session.requireCustomAppLockPasscode = false

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.evaluateAuthentication.count, 1)

        let preference = session.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceThenCustom)
    }

    func test_EvaluateAuthentication_ScreenLock_RequireCustomPasscode() {
        // Given
        session.lock = .screen
        session.requireCustomAppLockPasscode = true

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.evaluateAuthentication.count, 1)

        let preference = session.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .customOnly)
    }

    func test_EvaluateAuthentication_DatabaseLock() {
        // Given
        session.lock = .database

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.evaluateAuthentication.count, 1)

        let preference = session.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceOnly)
    }

    func test_EvaluateAuthentication_Granted() {
        // Given
        session.lock = .database
        session._authenticationResult = .granted

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.unlockDatabase_MockInvocations.count, 1)
        XCTAssertEqual(session.openApp.count, 1)
    }

    // @SF.Locking @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1
    // Check that database and screen is not unlocked when user denies authentication
    func test_EvaluateAuthentication_Denied() {
        // Given
        session.lock = .database
        session._authenticationResult = .denied
        authenticationType.current = .faceID

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.unlockDatabase_MockInvocations.count, 0)
        XCTAssertEqual(session.openApp.count, 0)
        XCTAssertEqual(presenter.results, [.authenticationDenied(.faceID)])
    }

    func test_EvaluateAuthentication_NeedCustomPasscode() {
        // Given
        session.lock = .screen
        session._authenticationResult = .needCustomPasscode

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.unlockDatabase_MockInvocations.count, 0)
        XCTAssertEqual(session.openApp.count, 0)
        XCTAssertEqual(presenter.results, [.customPasscodeNeeded])
    }

    // @SF.Locking @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1
    // Check that database and screen is not unlocked if user disables all authentication types
    func test_EvaluateAuthentication_Unavailable() {
        // Given
        session.lock = .screen
        session._authenticationResult = .unavailable

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.unlockDatabase_MockInvocations.count, 0)
        XCTAssertEqual(session.openApp.count, 0)
        XCTAssertEqual(presenter.results, [.authenticationUnavailable])
    }

    // MARK: - Open app lock

    func test_ItOpensAppLock() {
        // When
        sut.executeRequest(.openAppLock)

        // Then
        XCTAssertEqual(session.openApp.count, 1)
    }

}
