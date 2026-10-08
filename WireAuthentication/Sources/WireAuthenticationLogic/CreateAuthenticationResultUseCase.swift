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
import WireAuthenticationAPI
import WireLogging
import WireNetwork

package struct CreateAuthenticationResultUseCase: CreateAuthenticationResultUseCaseProtocol {

    private let networkStack: NetworkStack

    /// Whether to check the SSO IdP-change-detection flag. Only the SSO login
    /// paths can ever produce a `multiIngressIdentityProviderID` for this
    /// flag to matter, so other flows skip the extra `GET /system/settings`
    /// round trip entirely.

    private let checksSSOIdpChangeDetection: Bool

    package init(networkStack: NetworkStack, checksSSOIdpChangeDetection: Bool = false) {
        self.networkStack = networkStack
        self.checksSSOIdpChangeDetection = checksSSOIdpChangeDetection
    }

    package func invoke(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        emailCredentials: EmailCredentials?
    ) async throws -> AuthenticationResult {
        AuthenticationResult(
            userID: userID,
            cookies: cookies,
            accessToken: accessToken,
            emailCredentials: emailCredentials,
            backendEnvironment: networkStack.backendEnvironment,
            backendMetadata: try await networkStack.resolvedBackendMetadata(),
            proxyCredentials: await networkStack.proxyCredentials,
            ssoIdpChangeDetectionEnabled: checksSSOIdpChangeDetection
                ? await fetchSSOIdpChangeDetectionEnabled(accessToken: accessToken)
                : false
        )
    }

    /// Fails open (returns `false`) if the endpoint isn't available yet (older
    /// backends) or the request fails transiently, rather than blocking login.

    private func fetchSSOIdpChangeDetectionEnabled(accessToken: AccessToken?) async -> Bool {
        do {
            let networkService = try await networkStack.networkServices.rest
            let apiVersion = try await networkStack.resolvedAPIVersion()
            let api = SystemSettingsAPIBuilder(networkService: networkService).makeAPI(for: apiVersion)
            return try await api.getSystemSettings(accessToken: accessToken).ssoIdpChangeDetectionEnabled
        } catch SystemSettingsAPIError.unsupportedEndpointForAPIVersion {
            WireLogger.authentication.info(
                "Skipping SSO IdP change detection check: backend API version is below v18",
                attributes: .safePublic
            )
            return false
        } catch {
            WireLogger.authentication.error(
                "SSO IdP change detection check (GET /system/settings) failed, hadAccessToken: \(accessToken != nil): \(String(describing: error))",
                attributes: .safePublic
            )
            return false
        }
    }

}
