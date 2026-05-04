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
import WireNetwork

package struct DetermineAuthMethodUseCase: DetermineAuthMethodUseCaseProtocol {

    private let validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol
    private let authenticationAPI: AuthenticationAPI
    private let urlSession: URLSession

    package init(
        validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol,
        authenticationAPI: AuthenticationAPI,
        urlSession: URLSession
    ) {
        self.validateEmailOrSSOCode = validateEmailOrSSOCode
        self.authenticationAPI = authenticationAPI
        self.urlSession = urlSession
    }

    package func invoke(
        emailOrSSOCode: String
    ) async throws -> AuthenticationMethod {
        let emailOrSSOCode = try validateEmailOrSSOCode(input: emailOrSSOCode)

        switch emailOrSSOCode {
        case let .email(email, domain):
            return try await determineAuthMethod(email: email, domain: domain)
        case let .ssoCode(ssoCode):
            return .loginViaSSO(code: ssoCode)
        }
    }

    // MARK: - Private

    private func validateEmailOrSSOCode(
        input: String
    ) throws(DetermineAuthMethodUseCaseFailure) -> ValidatedEmailOrSSOCode {
        do {
            return try validateEmailOrSSOCode.invoke(input: input)
        } catch {
            throw .invalidEmailOrSSOCode
        }
    }

    @MainActor
    private func determineAuthMethod(email: String, domain: String) async throws -> AuthenticationMethod {
        let configuration: DomainRegistrationConfiguration
        do {
            configuration = try await authenticationAPI.getDomainRegistration(forEmail: email)
        } catch AuthenticationAPIError.unsupportedEndpointForAPIVersion {
            // Fallback if the API doesn't support the getDomainRegistration endpoint

            do {
                let onPremConfig = try await authenticationAPI.getOnPremConfigURL(forDomain: domain)
                return .onPremLogin(email: email, backendConfig: onPremConfig.configurationURL)
            } catch AuthenticationAPIError.configNotFound, AuthenticationAPIError.domainNotFound {
                return .loginOrRegisterViaEmail(email: email)
            }
        } catch AuthenticationAPIError.serviceUnavailable {
            return .loginOrRegisterViaEmail(email: email)
        }

        switch configuration.domainRedirect {
        case .noRegistration where configuration.isCloudAccountAlreadyRegistered == true:
            // The email domain has been claimed by an on-prem backend,
            // but there's already an existing cloud account registered.
            return .loginViaEmail(email: email, didDetectDomainConflict: true)

        case .none, .locked, .preAuthorized:
            return .loginOrRegisterViaEmail(email: email)

        case .noRegistration:
            return .loginViaEmail(email: email, didDetectDomainConflict: false)

        case .sso:
            guard let ssoCode = configuration.ssoCode else {
                throw AuthenticationAPIError.invalidResponse
            }
            return .loginViaSSO(code: ssoCode)

        case .backend:
            guard let configURL = configuration.backendURL else {
                throw AuthenticationAPIError.invalidResponse
            }

            do {
                let backendURL = try await fetchBackendConfigURL(from: configURL)
                return .onPremLogin(email: email, backendConfig: backendURL)
            } catch {
                throw AuthenticationAPIError.invalidResponse
            }
        }
    }

    private func fetchBackendConfigURL(from backendURL: URL) async throws -> URL {
        let (data, _) = try await urlSession.data(from: backendURL)

        let decoder = JSONDecoder()
        let domainInfo = try decoder.decode(DomainInfo.self, from: data)

        return domainInfo.configJsonURL
    }

}

private struct DomainInfo: Codable {

    let configJsonURL: URL
    let webappWelcomeURL: URL

    private enum CodingKeys: String, CodingKey {
        case configJsonURL = "config_json_url"
        case webappWelcomeURL = "webapp_welcome_url"
    }

}
