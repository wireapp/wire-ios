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

enum AppState: Equatable {
    case retryStart
    case headless
    case locked(UserSession)
    case authenticated(UserSession)
    case unauthenticated(error: NSError?)
    case blacklisted(reason: BlacklistReason)
    case jailbroken
    case certificateEnrollmentRequired
    case databaseFailure(reason: Error)
    case migrating
    case loading(account: Account, from: Account?)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.headless, .headless):
            return true
        case (.locked, .locked):
            return true
        case (.authenticated, .authenticated):
            return true
        case let (.unauthenticated(error1), .unauthenticated(error2)):
            return error1 === error2
        case let (.blacklisted(reason1), .blacklisted(reason2)):
            return reason1 == reason2
        case (jailbroken, jailbroken):
            return true
        case (certificateEnrollmentRequired, certificateEnrollmentRequired):
            return true
        case (databaseFailure, databaseFailure):
            return true
        case (migrating, migrating):
            return true
        case let (loading(accountTo1, accountFrom1), loading(accountTo2, accountFrom2)):
            return accountTo1 == accountTo2 && accountFrom1 == accountFrom2
        case (.retryStart, .retryStart):
            return true
        default:
            return false
        }
    }
}

<<<<<<< HEAD
extension AppState: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case .retryStart:
            "retryStart"
        case .headless:
            "headless"
        case .locked:
            "locked"
        case .authenticated:
            "authenticated"
        case .unauthenticated(error: let error):
            "unauthenticated"
        case .blacklisted(reason: let reason):
            "blacklisted"
        case .jailbroken:
            "jailbroken"
        case .certificateEnrollmentRequired:
            "certificateEnrollmentRequired"
        case .databaseFailure(reason: let reason):
            "databaseFailure"
        case .migrating:
            "migrating"
        case .loading(account: let account, from: let from):
            "loading"
        }
    }
}

// sourcery: AutoMockable
=======
extension AppState: SafeForLoggingStringConvertible {
    var safeForLoggingDescription: String {
        switch self {
        case .retryStart:
            return "retryStart"
        case .headless:
            return "headless"
        case .locked(let userSession):
            return "locked"
        case .authenticated(let userSession):
            return "authenticated"
        case .unauthenticated(let error):
            return "unauthenticated \(error?.localizedDescription ?? "<nil>")"
        case .blacklisted(let reason):
            return "blacklisted \(reason)"
        case .jailbroken:
            return "jailbroken"
        case .certificateEnrollmentRequired:
            return "certificateEnrollmentRequired"
        case .databaseFailure(let reason):
            return "databaseFailure \(reason)"
        case .migrating:
            return "migrating"
        case .loading(let account, let from):
            return "loading account: \(account.userIdentifier.safeForLoggingDescription), from: \(from?.userIdentifier.safeForLoggingDescription ?? "<nil>")"
        }
    }

}

>>>>>>> bed83ab999 (chore: add logs sending - WPB-9221 (#1538))
protocol AppStateCalculatorDelegate: AnyObject {
    func appStateCalculator(
        _ appStateCalculator: AppStateCalculator,
        didCalculate appState: AppState,
        completion: @escaping () -> Void
    )
}

final class AppStateCalculator {

    init() {
        setupApplicationNotifications()
    }

    deinit {
        removeObserverToken()
    }

    // MARK: - Public Property
    weak var delegate: AppStateCalculatorDelegate?
    var wasUnauthenticated: Bool = false

    // MARK: - Private Set Property
    private(set) var pendingAppState: AppState?
    private(set) var appState: AppState = .headless {
        willSet {
            if case .unauthenticated = appState {
                wasUnauthenticated = true
            } else {
                wasUnauthenticated = false
            }
        }
    }

    // MARK: - Private Property
    private var observerTokens: [NSObjectProtocol] = []
    private var hasEnteredForeground: Bool = false

    // MARK: - Private Implementation
    private func transition(
        to appState: AppState,
        completion: (() -> Void)? = nil
    ) {
        guard hasEnteredForeground  else {
            pendingAppState = appState
            completion?()
            return
        }

        guard self.appState != appState else {
            completion?()
            return
        }

        if case .blacklisted = self.appState, BackendInfo.apiVersion == nil {
            completion?()
            return
        }

        self.appState = appState
        self.pendingAppState = nil
<<<<<<< HEAD
        WireLogger.appState.debug("transitioning to app state: \(appState)")
        delegate?.appStateCalculator(self, didCalculate: appState) {
=======
        WireLogger.appState.debug("transitioning to app state \(appState.safeForLoggingDescription)", attributes: .safePublic)
        delegate?.appStateCalculator(self, didCalculate: appState, completion: {
>>>>>>> bed83ab999 (chore: add logs sending - WPB-9221 (#1538))
            completion?()
        }
    }
}

// MARK: - ApplicationStateObserving
extension AppStateCalculator: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func removeObserverToken() {
        observerTokens.removeAll()
    }

    func applicationDidBecomeActive() {
        hasEnteredForeground = true
        transition(to: pendingAppState ?? appState)
    }
}

// MARK: - SessionManagerDelegate
extension AppStateCalculator: SessionManagerDelegate {
    var isInAuthenticatedAppState: Bool {
        switch appState {
        case .authenticated:
            return true
        default:
            return false
        }
    }
    var isInUnathenticatedAppState: Bool {
        switch appState {
        case .unauthenticated:
            return true
        default:
            return false
        }
    }

    func sessionManagerWillLogout(
        error: Error?,
        userSessionCanBeTornDown: (() -> Void)?
    ) {
        transition(
            to: .unauthenticated(error: error as NSError?),
            completion: userSessionCanBeTornDown
        )
    }

    func sessionManagerDidFailToLogin(error: Error?) {
        transition(to: .unauthenticated(error: error as NSError?))
    }

    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        transition(to: .blacklisted(reason: reason))
    }

    func sessionManagerDidBlacklistJailbrokenDevice() {
        transition(to: .jailbroken)
    }

    func sessionManagerRequireCertificateEnrollment() {
        transition(to: .certificateEnrollmentRequired)
    }

    func sessionManagerDidEnrollCertificate(for activeSession: UserSession?) {
        if let activeSession {
            transition(to: .authenticated(activeSession))
        }
    }

    func sessionManagerDidFailToLoadDatabase(error: Error) {
        transition(to: .databaseFailure(reason: error))
    }

    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        transition(to: .migrating, completion: userSessionCanBeTornDown)
    }

    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        let appState: AppState = .loading(account: account,
                                          from: selectedAccount)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }

    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        // No op
    }

    func sessionManagerDidReportLockChange(forSession session: UserSession) {
        if session.isLocked {
            transition(to: .locked(session))
        } else {
            transition(to: .authenticated(session))
        }
    }

    func sessionManagerDidPerformFederationMigration(activeSession: UserSession?) {
        if let activeSession {
            transition(to: .authenticated(activeSession))
        } else {
            let error = NSError(code: .needsAuthenticationAfterMigration, userInfo: nil)
            transition(to: .unauthenticated(error: error))
        }
    }

    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?) {
        if let activeSession {
            transition(to: .authenticated(activeSession))
        } else {
            let error = NSError(code: .needsAuthenticationAfterMigration, userInfo: nil)
            transition(to: .unauthenticated(error: error))
        }
    }

    func sessionManagerAsksToRetryStart() {
        transition(to: .retryStart)
    }

    func sessionManagerDidCompleteInitialSync(for activeSession: UserSession?) {
        if let activeSession {
            transition(to: .authenticated(activeSession))
        }
    }
}

// MARK: - AuthenticationCoordinatorDelegate
extension AppStateCalculator: AuthenticationCoordinatorDelegate {
    func userAuthenticationDidComplete(userSession: UserSession) {
        if userSession.isLocked {
            transition(to: .locked(userSession))
        } else {
            transition(to: .authenticated(userSession))
        }
    }
}

extension AppStateCalculator {
    // NOTA BENE: THIS MUST BE USED JUST FOR TESTING PURPOSE
    func testHelper_setAppState(_ appState: AppState) {
        self.appState = appState
        transition(to: appState)
    }
}
