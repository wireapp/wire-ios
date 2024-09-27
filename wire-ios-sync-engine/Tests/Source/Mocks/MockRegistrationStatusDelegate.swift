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

final class MockRegistrationStatusDelegate: RegistrationStatusDelegate {
    var activationCodeSentCalled = 0
    var activationCodeSendingFailedCalled = 0
    var activationCodeSendingFailedError: Error?
    var activationCodeValidatedCalled = 0
    var activationCodeValidationFailedCalled = 0
    var activationCodeValidationFailedError: Error?
    var teamRegisteredCalled = 0
    var userRegisteredCalled = 0
    var teamRegistrationFailedCalled = 0
    var teamRegistrationFailedError: Error?
    var userRegistrationFailedCalled = 0
    var userRegistrationError: Error?

    func activationCodeSent() {
        activationCodeSentCalled += 1
    }

    func activationCodeSendingFailed(with error: Error) {
        activationCodeSendingFailedCalled += 1
        activationCodeSendingFailedError = error
    }

    func activationCodeValidated() {
        activationCodeValidatedCalled += 1
    }

    func activationCodeValidationFailed(with error: Error) {
        activationCodeValidationFailedCalled += 1
        activationCodeValidationFailedError = error
    }

    func teamRegistered() {
        teamRegisteredCalled += 1
    }

    func userRegistered() {
        userRegisteredCalled += 1
    }

    func teamRegistrationFailed(with error: Error) {
        teamRegistrationFailedCalled += 1
        teamRegistrationFailedError = error
    }

    func userRegistrationFailed(with error: Error) {
        userRegistrationFailedCalled += 1
        userRegistrationError = error
    }
}
