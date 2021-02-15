//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
import LocalAuthentication
@testable import WireDataModel

final class AppLockControllerTests: ZMBaseManagedObjectTest {

    var selfUser: ZMUser!

    override func setUp() {
        super.setUp()
        selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = .create()
        selfUser.isAppLockActive = true
    }
    
    override func tearDown() {
        selfUser = nil
        super.tearDown()
    }

    // MARK: - Configuration merging

    func test_ItCantBeTurnedOff_WhenItIsForced() {
        // Given
        let sut = createAppLockController(isForced: true)
        XCTAssertTrue(sut.isActive)

        // When
        sut.isActive = false
        
        // Then
        XCTAssertTrue(sut.isActive)
    }
    
    func test_ItCanBeTurnedOff_WhenItIsNotForced() {
        // Given
        let sut = createAppLockController(isForced: false)

        sut.isActive = true
        XCTAssertTrue(sut.isActive)

        // When
        sut.isActive = false

        // Then
        XCTAssertFalse(sut.isActive)
    }

    func test_ItHonorsTheTeamConfiguration_WhenSelfUserIsATeamUser() {
        // Given
        let sut = createAppLockController(isAvailable: true, isForced: false, timeout: 10)
        createTeamConfiguration(isAvailable: false, isForced: true, timeout: 30)

        // Then
        XCTAssertFalse(sut.isAvailable)
        XCTAssertTrue(sut.isForced)
        XCTAssertEqual(sut.timeout, 30)
    }

    func test_ItCanBeForced_EvenIfTheTeamConfigurationDoesntEnforceIt() {
        // Given
        let sut = createAppLockController(isForced: true)
        createTeamConfiguration(isForced: false)

        // Then
        XCTAssertTrue(sut.isForced)
    }

    // MARK: - Is locked

    func test_ItIsLocked_IfStateIsAlreadyLocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.locked)

        // Then
        XCTAssertTrue(sut.isLocked)
    }

    func test_ItIsNotLocked_IfStateIsAlreadyUnlocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.unlocked)

        // Then
        XCTAssertFalse(sut.isLocked)
    }

    func test_ItIsLocked_WhenTimeoutIsExceeded() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.needsChecking)
        sut._setLastCheckpoint(Date(timeIntervalSinceNow: -15))

        // Then
        XCTAssertTrue(sut.isLocked)
    }

    func test_ItIsNotLocked_WhenTimeoutIsExceeded_ButNotActive() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.needsChecking)
        sut._setLastCheckpoint(Date(timeIntervalSinceNow: -15))
        sut.isActive = false

        // Then
        XCTAssertFalse(sut.isLocked)
    }

    func test_ItIsNotLocked_WhenTimeoutIsNotExceeded() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.needsChecking)
        sut._setLastCheckpoint(Date(timeIntervalSinceNow: -5))

        // Then
        XCTAssertFalse(sut.isLocked)
    }

    // MARK: - Begin timer

    func test_ItBeginsTheTimer_IfUnlocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.unlocked)

        // When
        sut.beginTimer()

        // Then
        XCTAssertEqual(sut.state, .needsChecking)
        XCTAssertEqual(sut.lastCheckpoint.timeIntervalSinceNow, 0, accuracy: 0.1)
    }

    func test_ItDoesNotBeginTheTimer_IfNotLocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.locked)

        let lastCheckpoint = sut.lastCheckpoint

        // When
        sut.beginTimer()

        // Then
        XCTAssertEqual(sut.state, .locked)
        XCTAssertEqual(sut.lastCheckpoint, lastCheckpoint)
    }

    func test_ItDoesNotBeginTheTimer_IfAlreadyBegan() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.needsChecking)

        let lastCheckpoint = sut.lastCheckpoint

        // When
        sut.beginTimer()

        // Then
        XCTAssertEqual(sut.state, .needsChecking)
        XCTAssertEqual(sut.lastCheckpoint, lastCheckpoint)
    }

    // MARK: - Open

    func test_ItOpens_IfNotLocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.unlocked)

        let delegate = Delegate()
        sut.delegate = delegate

        // When
        XCTAssertNotNil(try sut.open())

        // Then
        XCTAssertTrue(delegate.didCallAppLockDidOpen)
    }

    func test_ItDoesNotOpen_IfLocked() {
        // Given
        let sut = createAppLockController(timeout: 10)
        sut._setState(.locked)

        let delegate = Delegate()
        sut.delegate = delegate

        // When
        XCTAssertThrowsError(try sut.open()) { error in
            guard
                let appLockError = error as? AppLockError,
                case .authenticationNeeded = appLockError
            else {
                return XCTFail()
            }
        }

        // Then
        XCTAssertFalse(delegate.didCallAppLockDidOpen)
    }
    

    // MARK: - Evaluate Authentication

    func test_ItEvaluatesAuthentication() {
        // If biometrics change then we need to verify the change with custom passcode.
        assert(
            input: (passcodePreference: .customOnly, canEvaluate: true, biometricsChanged: true),
            output: .needCustomPasscode
        )

        // Can evaluate and biometrics didn't change, so succeed.
        assert(
            input: (passcodePreference: .customOnly, canEvaluate: true, biometricsChanged: false),
            output: .granted
        )

        // If we can't evaluate, then it doesn't we need to custom passcode.
        assert(
            input: (passcodePreference: .customOnly, canEvaluate: false, biometricsChanged: true),
            output: .needCustomPasscode
        )

        // If we can't evaluate, then it doesn't we need to custom passcode.
        assert(
            input: (passcodePreference: .customOnly, canEvaluate: false, biometricsChanged: false),
            output: .needCustomPasscode
        )

        // If we can evaluate then there is a device passcode. A change in biometrics doesn't need to be
        // verified, since the user would have needed to enter the device passcode before changing settings.
        assert(
            input: (passcodePreference: .deviceThenCustom, canEvaluate: true, biometricsChanged: true),
            output: .granted
        )

        // Can evaluate, so succeed.
        assert(
            input: (passcodePreference: .deviceThenCustom, canEvaluate: true, biometricsChanged: false),
            output: .granted
        )

        // Can't evaluate (no device passcode), so ask for the custom passcode.
        assert(
            input: (passcodePreference: .deviceThenCustom, canEvaluate: false, biometricsChanged: true),
            output: .needCustomPasscode
        )

        // Can't evaluate (no device passcode), so ask for the custom passcode.
        assert(
            input: (passcodePreference: .deviceThenCustom, canEvaluate: false, biometricsChanged: false),
            output: .needCustomPasscode
        )

        // Device passcode exists so the biometrics change doesn't matter.
        assert(
            input: (passcodePreference: .deviceOnly, canEvaluate: true, biometricsChanged: true),
            output: .granted
        )

        // Can evaluate, so succeed.
        assert(
            input: (passcodePreference: .deviceOnly, canEvaluate: true, biometricsChanged: false),
            output: .granted
        )

        // Can't evaluate (no device passcode).
        performIgnoringZMLogError {
            self.assert(
                input: (passcodePreference: .deviceOnly, canEvaluate: false, biometricsChanged: true),
                output: .unavailable
            )
        }

        // Can't evaluate (no device passcode).
        performIgnoringZMLogError {
            self.assert(
                input: (passcodePreference: .deviceOnly, canEvaluate: false, biometricsChanged: false),
                output: .unavailable
            )
        }
    }

    func test_ItEvaluatesAuthentication_WithCorrectCustomPasscode() throws {
        // Given
        let sut = createAppLockController()
        try sut.updatePasscode("boo!")

        let mockBiometricsState = MockBiometricsState()
        sut.biometricsState = mockBiometricsState

        // When
        let result = sut.evaluateAuthentication(customPasscode: "boo!")

        // Then
        XCTAssertEqual(result, .granted)
        XCTAssertFalse(sut.isLocked)
        XCTAssertTrue(mockBiometricsState.didCallPersistState)

        // Clean up
        try sut.deletePasscode()
    }

    func test_ItEvaluatesAuthentication_WithInCorrectCustomPasscode() throws {
        // Given
        let sut = createAppLockController()
        try sut.updatePasscode("boo!")

        let mockBiometricsState = MockBiometricsState()
        sut.biometricsState = mockBiometricsState

        // When
        let result = sut.evaluateAuthentication(customPasscode: "ahh!")

        // Then
        XCTAssertEqual(result, .denied)
        XCTAssertTrue(sut.isLocked)
        XCTAssertFalse(mockBiometricsState.didCallPersistState)

        // Clean up
        try sut.deletePasscode()
    }

    // MARK: - Passcode management

    func test_ItUpdatesThePasscode() throws {
        // Given
        let sut = createAppLockController()

        // When
        XCTAssertNoThrow(try sut.updatePasscode("boo!"))

        // Then
        XCTAssertEqual(sut.fetchPasscode(), "boo!".data(using: .utf8)!)

        // Clean up
        try sut.deletePasscode()
    }

    func test_ItOverwritesExistingPasscode_WhenUpdatingThePasscode() throws {
        // Given
        let sut = createAppLockController()
        try sut.updatePasscode("boo!")

        // When
        XCTAssertNoThrow(try sut.updatePasscode("ahh!"))

        // Then
        XCTAssertEqual(sut.fetchPasscode(), "ahh!".data(using: .utf8)!)

        // Clean up
        try sut.deletePasscode()
    }

    func test_IsCustomPasscodeSet() throws {
        // Given
        let sut = createAppLockController()
        XCTAssertFalse(sut.isCustomPasscodeSet)

        // When
        try sut.updatePasscode("boo!")

        // Then
        XCTAssertTrue(sut.isCustomPasscodeSet)

        // Clean up
        try sut.deletePasscode()
    }

}

// MARK: - Helpers

extension AppLockControllerTests {

    typealias Input = (passcodePreference: AppLockPasscodePreference, canEvaluate: Bool, biometricsChanged: Bool)
    typealias Output = AppLockAuthenticationResult
    
    private func assert(input: Input, output: Output, file: StaticString = #file, line: UInt = #line) {
        let sut = createAppLockController()

        let mockBiometricsState = MockBiometricsState()
        mockBiometricsState._biometricsChanged = input.biometricsChanged
        sut.biometricsState = mockBiometricsState

        let context = MockLAContext(canEvaluate: input.canEvaluate)

        let assertion: (Output, LAContextProtocol) -> Void = { result, _ in
            XCTAssertEqual(result, output, file: file, line: line)

            if output == .granted {
                XCTAssertFalse(sut.isLocked, "isLocked should be false", file: file, line: line)
            } else {
                XCTAssertTrue(sut.isLocked, "isLocked should be true", file: file, line: line)
            }
        }
        
        sut.evaluateAuthentication(passcodePreference: input.passcodePreference,
                                   description: "",
                                   context: context,
                                   callback: assertion)
    }
    
    private func createAppLockController(isAvailable: Bool = true,
                                         isForced: Bool = false,
                                         timeout: UInt = 900,
                                         requireCustomPasscode: Bool = false) -> AppLockController {

        let config = AppLockController.Config(isAvailable: isAvailable,
                                              isForced: isForced,
                                              timeout: timeout,
                                              requireCustomPasscode: requireCustomPasscode
        )

        return AppLockController(userId: selfUser.remoteIdentifier, config: config, selfUser: selfUser)
    }

    private func createTeamConfiguration(isAvailable: Bool = true, isForced: Bool = false, timeout: UInt = 30) {
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)

        let config = Feature.AppLock.Config.init(enforceAppLock: isForced, inactivityTimeoutSecs: timeout)
        let configData = try? JSONEncoder().encode(config)

        _ = Feature.insert(name: .appLock,
                           status: isAvailable ? .enabled : .disabled,
                           config: configData,
                           team: team,
                           context: uiMOC)
    }

    class Delegate: AppLockDelegate {

        var didCallAppLockDidOpen = false

        func appLockDidOpen(_ appLock: AppLockType) {
            didCallAppLockDidOpen = true
        }

    }

}
