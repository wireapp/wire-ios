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

import XCTest
@testable import Wire
import WireDataModel

class MockAuthenticationStateControllerDelegate: AuthenticationStateControllerDelegate {

    var lastKnownStep: AuthenticationFlowStep?
    var lastKnownChangeMode: AuthenticationStateController.StateChangeMode?

    func stateDidChange(_ newState: AuthenticationFlowStep, mode: AuthenticationStateController.StateChangeMode) {
        lastKnownStep = newState
        lastKnownChangeMode = mode
    }

}

class AuthenticationStateControllerTests: XCTestCase {

    var stateController: AuthenticationStateController!
    var delegate: MockAuthenticationStateControllerDelegate!

    override func setUp() {
        super.setUp()
        delegate = MockAuthenticationStateControllerDelegate()
        stateController = AuthenticationStateController()
        stateController.delegate = delegate
    }

    override func tearDown() {
        delegate = nil
        stateController = nil
        super.tearDown()
    }

    func testThatItProvidesCorrectInitialState() {
        XCTAssertEqual(stateController.currentStep, .start)
        XCTAssertEqual(stateController.stack, [.start])
    }

    func testThatItAdvancesStateWithUIStep() {
        // WHEN
        stateController.transition(to: .landingScreen)

        // THEN
        XCTAssertEqual(stateController.currentStep, .landingScreen)
        XCTAssertEqual(stateController.stack, [.start, .landingScreen])
        XCTAssertEqual(delegate.lastKnownChangeMode, .normal)
        XCTAssertEqual(delegate.lastKnownStep, .landingScreen)
    }

    func testThatItAdvancesStateWithNonUIStep() {
        // GIVEN
        let credentials = ZMEmailCredentials(email: "test@example.com", password: "testtest")
        let emailStep = AuthenticationFlowStep.authenticateEmailCredentials(credentials)

        // WHEN
        stateController.transition(to: .authenticateEmailCredentials(credentials))

        // THEN
        XCTAssertEqual(stateController.currentStep, emailStep)
        XCTAssertEqual(stateController.stack, [.start, emailStep])
        XCTAssertEqual(delegate.lastKnownChangeMode, .normal)
        XCTAssertEqual(delegate.lastKnownStep, emailStep)

    }

    func testThatItAdvancesStateWithReset() {
        // WHEN
        stateController.transition(to: .landingScreen, mode: .reset)

        // THEN
        XCTAssertEqual(stateController.currentStep, .landingScreen)
        XCTAssertEqual(stateController.stack, [.landingScreen])
        XCTAssertEqual(delegate.lastKnownChangeMode, .reset)
        XCTAssertEqual(delegate.lastKnownStep, .landingScreen)
    }

    func testThatItAdvancesStateWithRewind() {
        // GIVEN
        let user = UnregisteredUser()
        stateController.transition(to: .landingScreen, mode: .normal)
        stateController.transition(to: .createCredentials(user), mode: .normal)

        // WHEN
        stateController.transition(to: .incrementalUserCreation(user, .setName), mode: .rewindToOrReset(to: .createCredentials(user)))

        // THEN
        XCTAssertEqual(stateController.currentStep, .incrementalUserCreation(user, .setName))
        XCTAssertEqual(stateController.stack, [.start, .landingScreen, .createCredentials(user), .incrementalUserCreation(user, .setName)])
        XCTAssertEqual(delegate.lastKnownChangeMode, .rewindToOrReset(to: .createCredentials(user)))
        XCTAssertEqual(delegate.lastKnownStep, .incrementalUserCreation(user, .setName))
    }

    func testThatItAdvancesStateWithRewindButReset() {
        // GIVEN
        let user = UnregisteredUser()
        stateController.transition(to: .landingScreen, mode: .normal)

        // WHEN
        stateController.transition(to: .incrementalUserCreation(user, .setName), mode: .rewindToOrReset(to: .createCredentials(user)))

        // THEN
        XCTAssertEqual(stateController.currentStep, .incrementalUserCreation(user, .setName))
        XCTAssertEqual(stateController.stack, [.incrementalUserCreation(user, .setName)])
        XCTAssertEqual(delegate.lastKnownChangeMode, .rewindToOrReset(to: .createCredentials(user)))
        XCTAssertEqual(delegate.lastKnownStep, .incrementalUserCreation(user, .setName))
    }

    func testThatItDoesNotUnwindFromInitialState() {
        // GIVEN
        XCTAssertEqual(stateController.stack, [.start])

        // WHEN
        stateController.unwindState()

        // THEN
        XCTAssertEqual(stateController.currentStep, .start)
        XCTAssertEqual(stateController.stack, [.start])
    }

    func testThatItUnwindsFromUIToPreviousUIStep() {
        // GIVEN
        let phoneNumber = "+4912345678900"

        stateController.transition(to: .landingScreen, mode: .reset)
        stateController.transition(to: .provideCredentials(.email, nil))
        stateController.transition(to: .requestPhoneVerificationCode(phoneNumber: phoneNumber, isResend: false))

        XCTAssertEqual(stateController.stack, [
            .landingScreen,
            .provideCredentials(.email, nil),
            .requestPhoneVerificationCode(phoneNumber: phoneNumber, isResend: false)
        ])

        // WHEN
        stateController.unwindState()

        // THEN
        XCTAssertEqual(stateController.currentStep, .provideCredentials(.email, nil)) // we should rewind to n-1 step
        XCTAssertEqual(stateController.stack, [.landingScreen, .provideCredentials(.email, nil)])
    }

    func testThatItUnwindsFromNonUIToUIState() {
        // GIVEN
        let phoneNumber = "+4912345678900"

        stateController.transition(to: .landingScreen, mode: .reset)
        stateController.transition(to: .provideCredentials(.phone, nil)) // user logs in with phone number
        stateController.transition(to: .requestPhoneVerificationCode(phoneNumber: phoneNumber, isResend: false))
        stateController.transition(to: .enterPhoneVerificationCode(phoneNumber: phoneNumber))

        XCTAssertEqual(stateController.stack, [
            .landingScreen,
            .provideCredentials(.phone, nil),
            .requestPhoneVerificationCode(phoneNumber: phoneNumber, isResend: false), // non-ui
            .enterPhoneVerificationCode(phoneNumber: phoneNumber)
        ])

        // WHEN
        stateController.unwindState() // user taps back button on enter code screen

        // THEN
        XCTAssertEqual(stateController.currentStep, .provideCredentials(.phone, nil)) // we should rewind to n-2, because n-1 is non-ui
        XCTAssertEqual(stateController.stack, [.landingScreen, .provideCredentials(.phone, nil)])
    }

}
