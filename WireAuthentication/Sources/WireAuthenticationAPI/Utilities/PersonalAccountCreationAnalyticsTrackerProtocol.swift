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

// sourcery: AutoMockable
public protocol PersonalAccountCreationAnalyticsTrackerProtocol {

    /// Start analytics after the user agreed.

    func setUp()

    /// Stop analytics when the account creation flow is left.

    func tearDown()

    /// Invoked when the user submits the personal account creation form.
    /// - Parameter multiplePasswordAttemptsNeeded: `true` if it took the user more than one try to enter a valid password.

    func trackPersonalAccountCreationStart(multiplePasswordAttemptsNeeded: Bool)

    /// Invoked when the user is presented the UI for accepting the terms of use.

    func trackPersonalAccountCreationReachedTermsOfUseConfirmation()

    /// Invoked when the user is presented the UI for entering the verification code.

    func trackPersonalAccountCreationReachedVerificationCode()

    /// Invoked when the user enters an invalid verification code.

    func trackPersonalAccountCreationFailedCodeVerification()

    /// Invoked when the user is presented the UI for choosing a username.

    func trackPersonalAccountCreationReachedUsernameForm()

    /// Invoked when the user completed the account creation.

    func trackPersonalAccountCreationCompletion()

}
