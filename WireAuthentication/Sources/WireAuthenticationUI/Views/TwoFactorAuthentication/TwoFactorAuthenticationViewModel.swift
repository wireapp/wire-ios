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

import Observation
import WireAuthenticationAPI
import WireLogging

@MainActor
@Observable
package final class TwoFactorAuthenticationViewModel: TwoFactorAuthenticationViewModelProtocol {

    package private(set) var isTwoFactorAuthenticationEnabled: Bool?
    package private(set) var isLoading = true
    package private(set) var registeredAuthenticatorApps: [RegisteredAuthenticatorApp]?
    package private(set) var recoveryCodesStatus: RecoveryCodesStatus?

    @ObservationIgnored package var onShowAuthenticatorApps: (@MainActor () -> Void)?
    @ObservationIgnored package var onShowRecoveryCodes: (@MainActor () -> Void)?

    private let isTwoFactorAuthenticationEnabledUseCase: any IsTwoFactorAuthenticationEnabledUseCaseProtocol
    private let getRegisteredAuthenticatorAppsUseCase: any GetRegisteredAuthenticatorAppsUseCaseProtocol
    private let getRecoveryCodesStatusUseCase: any GetRecoveryCodesStatusUseCaseProtocol
    private let logger: any LoggerProtocol

    package init(
        isTwoFactorAuthenticationEnabledUseCase: any IsTwoFactorAuthenticationEnabledUseCaseProtocol,
        getRegisteredAuthenticatorAppsUseCase: any GetRegisteredAuthenticatorAppsUseCaseProtocol,
        getRecoveryCodesStatusUseCase: any GetRecoveryCodesStatusUseCaseProtocol,
        logger: any LoggerProtocol
    ) {
        self.isTwoFactorAuthenticationEnabledUseCase = isTwoFactorAuthenticationEnabledUseCase
        self.getRegisteredAuthenticatorAppsUseCase = getRegisteredAuthenticatorAppsUseCase
        self.getRecoveryCodesStatusUseCase = getRecoveryCodesStatusUseCase
        self.logger = logger
    }

    package func loadStatus() async {
        isLoading = true
        registeredAuthenticatorApps = nil
        recoveryCodesStatus = nil
        defer { isLoading = false }

        do {
            isTwoFactorAuthenticationEnabled = try await isTwoFactorAuthenticationEnabledUseCase.invoke()
            if isTwoFactorAuthenticationEnabled == true {
                async let apps: Void = loadAuthenticatorApps()
                async let codes: Void = loadRecoveryCodesStatus()
                _ = await (apps, codes)
            }
        } catch is CancellationError {
            // The view's task is cancelled when leaving the screen.
        } catch {
            // TODO: [WPB-29475] Handle errors when loading two-factor authentication status.
            logger.error("Failed to load two-factor authentication status: " + String(reflecting: error))
        }
    }

    package func setUp() {
        // TODO: [WPB-29475] Present the two-factor authentication setup flow.
    }

    package func turnOff() {
        // TODO: [WPB-29475] Implement turning off two-factor authentication.
    }

    package func showAuthenticatorApps() {
        onShowAuthenticatorApps?()
    }

    package func showRecoveryCodes() {
        onShowRecoveryCodes?()
    }

    private func loadAuthenticatorApps() async {
        do {
            registeredAuthenticatorApps = try await getRegisteredAuthenticatorAppsUseCase.invoke()
        } catch is CancellationError {
            // The view's task is cancelled when leaving the screen.
        } catch {
            // TODO: [WPB-29475] Handle errors when loading registered authenticator apps.
            logger.error("Failed to load registered authenticator apps: " + String(reflecting: error))
        }
    }

    private func loadRecoveryCodesStatus() async {
        do {
            recoveryCodesStatus = try await getRecoveryCodesStatusUseCase.invoke()
        } catch is CancellationError {
            // The view's task is cancelled when leaving the screen.
        } catch {
            // TODO: [WPB-29475] Handle errors when loading recovery code counts.
            logger.error("Failed to load recovery code counts: " + String(reflecting: error))
        }
    }
}
