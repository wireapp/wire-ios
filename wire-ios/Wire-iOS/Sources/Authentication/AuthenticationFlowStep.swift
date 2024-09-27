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
import WireSyncEngine

// MARK: - NoHistoryContext

/// The context that caused the user to not have a complete history.
enum NoHistoryContext {
    /// The user signed into this device for the first time.
    case newDevice

    /// The user logged out.
    case loggedOut
}

// MARK: - AuthenticationFlowStep

/// Steps of the authentication flow.
indirect enum AuthenticationFlowStep: Equatable {
    // Initial Steps
    case start
    case landingScreen
    case reauthenticate(credentials: LoginCredentials?, numberOfAccounts: Int, isSignedOut: Bool)

    // Sign-In
    case provideCredentials(AuthenticationPrefilledCredentials?)
    case enterEmailVerificationCode(email: String, password: String, isResend: Bool)
    case authenticateEmailCredentials(UserEmailCredentials)
    case companyLogin
    case switchBackend(url: URL)

    // Post Sign-In
    case noHistory(credentials: UserCredentials?, context: NoHistoryContext)
    case clientManagement(clients: [UserClient])
    case deleteClient(clients: [UserClient])
    case addEmailAndPassword
    case enrollE2EIdentity
    case enrollE2EIdentitySuccess(String)
    case addUsername
    case registerEmailCredentials(UserEmailCredentials, isResend: Bool)
    case pendingEmailLinkVerification(UserEmailCredentials)
    case pendingInitialSync

    // Registration
    case createCredentials(UnregisteredUser)
    case sendActivationCode(unverifiedEmail: String, user: UnregisteredUser, isResend: Bool)
    case enterActivationCode(unverifiedEmail: String, user: UnregisteredUser)
    case activateCredentials(unverifiedEmail: String, user: UnregisteredUser, code: String)
    case incrementalUserCreation(UnregisteredUser, IntermediateRegistrationStep)
    case createUser(UnregisteredUser)

    // Configuration
    case configureDevice

    // MARK: Internal

    // MARK: - Properties

    /// Whether the authentication steps generates a user interface.
    var needsInterface: Bool {
        switch self {
        // Initial Steps
        case .start: false
        case .landingScreen: true
        case .reauthenticate: true
        // Sign-In
        case .provideCredentials: true
        case .enterEmailVerificationCode: true
        case .authenticateEmailCredentials: false
        case .registerEmailCredentials: false
        case .companyLogin: false
        case .switchBackend: true
        // Post Sign-In
        case .noHistory: true
        case .clientManagement: true
        case .deleteClient: true
        case .addEmailAndPassword: true
        case .enrollE2EIdentity: true
        case .enrollE2EIdentitySuccess: true
        case .addUsername: true
        case .pendingInitialSync: false
        case .pendingEmailLinkVerification: true
        // Registration
        case .createCredentials: true
        case .sendActivationCode: false
        case .enterActivationCode: true
        case .activateCredentials: false
        case let .incrementalUserCreation(_, intermediateStep): intermediateStep.needsInterface
        case .createUser: false
        // Configuration
        case .configureDevice: false
        }
    }
}

// MARK: - IntermediateRegistrationStep

/// Intermediate steps required for user registration.
enum IntermediateRegistrationStep: Equatable {
    case start, provideMarketingConsent, setName, setPassword

    // MARK: Internal

    var needsInterface: Bool {
        switch self {
        case .start: false
        case .provideMarketingConsent: false
        default: true
        }
    }
}
