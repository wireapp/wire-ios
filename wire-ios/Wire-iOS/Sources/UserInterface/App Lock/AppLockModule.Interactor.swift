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
import LocalAuthentication
import WireDataModel
import WireSyncEngine

// MARK: - AppLockModule.Interactor

extension AppLockModule {
    final class Interactor: InteractorInterface {
        // MARK: Lifecycle

        init(
            userSession: UserSession,
            authenticationType: AuthenticationTypeProvider = AuthenticationTypeDetector(),
            applicationStateProvider: ApplicationStateProvider = UIApplication.shared
        ) {
            self.userSession = userSession
            self.authenticationType = authenticationType
            self.applicationStateProvider = applicationStateProvider
        }

        // MARK: Internal

        // MARK: - Properties

        weak var presenter: AppLockPresenterInteractorInterface!

        let dispatchGroup = DispatchGroup()

        // MARK: Private

        private let userSession: UserSession
        private let authenticationType: AuthenticationTypeProvider
        private let applicationStateProvider: ApplicationStateProvider

        /// The message to display on the OS authentication screen.

        private let deviceAuthenticationDescription = L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.description

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

// MARK: - AppLockModule.Interactor + AppLockInteractorPresenterInterface

extension AppLockModule.Interactor: AppLockInteractorPresenterInterface {
    func executeRequest(_ request: AppLockModule.Request) {
        switch request {
        case .initiateAuthentication(requireActiveApp: true) where applicationState != .active:
            return

        case .initiateAuthentication where !isAuthenticationNeeded:
            openAppLock()

        case .initiateAuthentication where needsToCreateCustomPasscode:
            presenter.handleResult(.customPasscodeCreationNeeded(shouldInform: needsToNotifyUser))

        case .initiateAuthentication:
            presenter.handleResult(.readyForAuthentication(shouldInform: needsToNotifyUser))

        case .evaluateAuthentication:
            guard let preference = passcodePreference else {
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
        try? userSession.unlockDatabase()
    }

    private func openAppLock() {
        try? userSession.openAppLock()
    }
}
