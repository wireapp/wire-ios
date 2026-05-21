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
import WireDataModel
import WireLogging
import WireSyncEngine

extension AppLockModule {

    final class Interactor: InteractorInterface {

        // MARK: - Properties

        weak var presenter: AppLockPresenterInteractorInterface!

        private let userSession: UserSession
        private let authenticationType: AuthenticationTypeProvider
        private let applicationStateProvider: ApplicationStateProvider

        let dispatchGroup = DispatchGroup()

        /// The message to display on the OS authentication screen.

        private let deviceAuthenticationDescription = L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.description

        // MARK: - Life cycle

        init(
            userSession: UserSession,
            authenticationType: AuthenticationTypeProvider = AuthenticationTypeDetector(),
            applicationStateProvider: ApplicationStateProvider = UIApplication.shared
        ) {

            self.userSession = userSession
            self.authenticationType = authenticationType
            self.applicationStateProvider = applicationStateProvider
        }

        // MARK: - Methods

        private var passcodePreference: PasscodePreference? {
            guard let lock = userSession.lock else { return nil }

            switch lock {
            case .screen where userSession.requireCustomAppLockPasscode:
                return .customOnly
            case .screen:
                return .deviceThenCustom
            case .database:
                return .deviceOnly
            }
        }

        private var needsToNotifyUser: Bool {
            userSession.needsToNotifyUserOfAppLockConfiguration
        }

        private var needsToCreateCustomPasscode: Bool {
            guard passcodePreference != .deviceOnly else { return false }
            guard !userSession.isCustomAppLockPasscodeSet else { return false }
            return userSession.requireCustomAppLockPasscode || authenticationType.current == .unavailable
        }

        private var isAuthenticationNeeded: Bool {
            passcodePreference != nil
        }

        private var applicationState: UIApplication.State {
            applicationStateProvider.applicationState
        }

    }

}

// MARK: - Execute request

extension AppLockModule.Interactor: AppLockInteractorPresenterInterface {

    func executeRequest(_ request: AppLockModule.Request) {
        WireLogger.appLock.info(
            "Interactor.executeRequest(\(request)) — userSession.lock=\(String(describing: userSession.lock)), passcodePreference=\(String(describing: passcodePreference)), isAuthenticationNeeded=\(isAuthenticationNeeded)",
            attributes: .safePublic
        )
        switch request {
        case .initiateAuthentication where !isAuthenticationNeeded:
            WireLogger.appLock.info(
                "initiateAuthentication — no auth needed, opening app lock directly",
                attributes: .safePublic
            )
            openAppLock()

        case .initiateAuthentication where needsToCreateCustomPasscode:
            presenter.handleResult(.customPasscodeCreationNeeded(shouldInform: needsToNotifyUser))

        case .initiateAuthentication:
            presenter.handleResult(.readyForAuthentication(shouldInform: needsToNotifyUser))

        case .evaluateAuthentication:
            guard let preference = passcodePreference else {
                WireLogger.appLock.warn(
                    "evaluateAuthentication — passcodePreference is nil, granting without prompt",
                    attributes: .safePublic
                )
                handleAuthenticationResult(.granted)
                return
            }

            userSession.evaluateAppLockAuthentication(
                passcodePreference: preference,
                description: deviceAuthenticationDescription,
                callback: handleAuthenticationResult
            )

        case .openAppLock:
            openAppLock()
        }
    }

    private func handleAuthenticationResult(_ result: AppLockModule.AuthenticationResult) {
        DispatchQueue.main.async(group: dispatchGroup) { [weak self] in
            guard let self else { return }

            switch result {
            case .granted:
                unlockDatabase()
                openAppLock()

            case .denied:
                presenter.handleResult(.authenticationDenied(authenticationType.current))

            case .needCustomPasscode:
                presenter.handleResult(.customPasscodeNeeded)

            case .unavailable:
                presenter.handleResult(.authenticationUnavailable)
            }
        }
    }

    private func unlockDatabase() {
        WireLogger.appLock.info(
            "Interactor.unlockDatabase — calling userSession.unlockDatabase() after granted auth",
            attributes: .safePublic
        )
        try? userSession.unlockDatabase()
    }

    private func openAppLock() {
        WireLogger.appLock.info(
            "Interactor.openAppLock — calling userSession.openAppLock()",
            attributes: .safePublic
        )
        try? userSession.openAppLock()
    }

}
