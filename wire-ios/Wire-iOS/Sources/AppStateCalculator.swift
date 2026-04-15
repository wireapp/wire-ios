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
import WireLogging
import WireNetwork
import WireSyncEngine

enum AppState: Equatable {
    case retryStart
    case headless
    case locked(UserSession)
    case authenticated(UserSession)
    case unauthenticated(accountID: UUID?, environment: BackendEnvironment2?, error: NSError?)
    case blacklisted(reason: BlacklistReason)
    case jailbroken
    case certificateEnrollmentRequired
    case databaseFailure(reason: Error)
    case migrating
    case syncFailure(error: any Error, onRetry: () -> Void)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.headless, .headless):
            true
        case (.locked, .locked):
            true
        case let (.authenticated(userSession1), .authenticated(userSession2)):
            userSession1 === userSession2
        case let (.unauthenticated(id1, env1, error1), .unauthenticated(id2, env2, error2)):
            id1 == id2 &&
                env1 == env2 &&
                error1 === error2
        case let (.blacklisted(reason1), .blacklisted(reason2)):
            reason1 == reason2
        case (jailbroken, jailbroken):
            true
        case (certificateEnrollmentRequired, certificateEnrollmentRequired):
            true
        case (databaseFailure, databaseFailure):
            true
        case (migrating, migrating):
            true
        case (.retryStart, .retryStart):
            true
        default:
            false
        }
    }
}

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
        case let .unauthenticated(_, _, error):
            "unauthenticated: \(error.debugDescription)"
        case let .blacklisted(reason: reason):
            "blacklisted: \(reason)"
        case .jailbroken:
            "jailbroken"
        case .certificateEnrollmentRequired:
            "certificateEnrollmentRequired"
        case let .databaseFailure(reason: reason):
            "databaseFailure: \(reason)"
        case .migrating:
            "migrating"
        case let .syncFailure(error, _):
            "syncFailure: \(error.localizedDescription)"
        }
    }
}

extension AppState: SafeForLoggingStringConvertible {
    var safeForLoggingDescription: String {
        switch self {
        case .retryStart:
            "retryStart"
        case .headless:
            "headless"
        case .locked:
            "locked"
        case .authenticated:
            "authenticated"
        case let .unauthenticated(_, _, error):
            "unauthenticated \(error?.localizedDescription ?? "<nil>")"
        case let .blacklisted(reason):
            "blacklisted \(reason)"
        case .jailbroken:
            "jailbroken"
        case .certificateEnrollmentRequired:
            "certificateEnrollmentRequired"
        case let .databaseFailure(reason):
            "databaseFailure \(reason)"
        case .migrating:
            "migrating"
        case let .syncFailure(error, _):
            "syncFailure \(error.localizedDescription)"
        }
    }

}

// sourcery: AutoMockable
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
        guard let delegate else {
            fatalInternal("AppStateCalculator has no delegate")
            completion?()
            return
        }

        let appState = validAppState(from: appState)

        guard hasEnteredForeground  else {
            pendingAppState = appState
            completion?()
            return
        }

        guard self.appState != appState else {
            completion?()
            return
        }

        self.appState = appState
        pendingAppState = nil

        WireLogger.appState.info(
            "transitioning to app state \(appState.safeForLoggingDescription)",
            attributes: .safePublic
        )
        delegate.appStateCalculator(self, didCalculate: appState) {
            completion?()
        }
    }

    private func validAppState(from appState: AppState) -> AppState {
        switch appState {
        case let .authenticated(session) where session.isBuildBlacklisted:
            .blacklisted(reason: .appVersionBlacklisted)
        default:
            appState
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
            true
        default:
            false
        }
    }

    var isInUnathenticatedAppState: Bool {
        switch appState {
        case .unauthenticated:
            true
        default:
            false
        }
    }

    func sessionManagerWillLogout(
        accountID: UUID?,
        environment: BackendEnvironment2?,
        error: Error?,
        userSessionCanBeTornDown: (() -> Void)?
    ) {
        transition(
            to: .unauthenticated(
                accountID: accountID,
                environment: environment,
                error: error as NSError?
            ),
            completion: userSessionCanBeTornDown
        )
    }

    func sessionManagerDidFailToLoadSession(
        for account: Account,
        error: SessionManager.SessionLoadingFailure
    ) {
        switch error {
        case .buildIsBlacklisted:
            transition(to: .blacklisted(reason: .appVersionBlacklisted))
        case .backendIsObsolete:
            transition(to: .blacklisted(reason: .backendAPIVersionObsolete))
        case .clientIsObsolete:
            transition(to: .blacklisted(reason: .clientAPIVersionObsolete))
        case let .networkError(code):
            transition(to: .blacklisted(reason: .networkError(code: code)))
        case .genericError:
            transition(to: .blacklisted(reason: .genericError))
        case let .databaseError(error):
            transition(to: .databaseFailure(reason: error))
        }
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
            let error = NSError(userSessionErrorCode: .needsAuthenticationAfterMigration, userInfo: nil)
            transition(to: .unauthenticated(accountID: nil, environment: nil, error: error))
        }
    }

    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?) {
        if let activeSession {
            transition(to: .authenticated(activeSession))
        } else {
            let error = NSError(userSessionErrorCode: .needsAuthenticationAfterMigration, userInfo: nil)
            transition(to: .unauthenticated(accountID: nil, environment: nil, error: error))
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

    func sessionManagerDidFailSyncing(
        error: any Error,
        retryHandler: @escaping () -> Void
    ) {
        transition(to: .syncFailure(error: error, onRetry: retryHandler))
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
