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

import Foundation
import WireAuthenticationAPI
import WireLogging

@MainActor
package class SwitchBackendConfirmationViewModel: ObservableObject {

    private typealias Strings = L10n.SwitchBackendConfirmation

    package typealias Factory =
        FetchSSOURLUseCaseFactory &
        ResolveBackendMetadataUseCaseFactory

    // MARK: - State

    let items: [ItemUIModel]

    private let router: any Router
    private let factory: any Factory
    private let email: String
    private let backendConfig: BackendConfig

    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    // MARK: - Life cycle

    package init(
        router: any Router,
        factory: any Factory,
        email: String,
        backendConfig: BackendConfig
    ) {
        self.router = router
        self.factory = factory
        self.email = email
        self.backendConfig = backendConfig
        self.items = [
            ItemUIModel(
                title: Strings.backendName,
                value: backendConfig.title,
                isURL: false
            ),
            ItemUIModel(
                title: Strings.backendUrl,
                value: backendConfig.endpoints.backendURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.backendWsurl,
                value: backendConfig.endpoints.backendWSURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.blacklistUrl,
                value: backendConfig.endpoints.blackListURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.teamsUrl,
                value: backendConfig.endpoints.teamsURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.accountsUrl,
                value: backendConfig.endpoints.accountsURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.websiteUrl,
                value: backendConfig.endpoints.websiteURL.absoluteString,
                isURL: true
            )
        ]
    }

    func confirm() async {
        isLoading = true

        defer {
            isLoading = false
        }

        // If authenticated proxy is required, go straight to email login because we need to
        // get proxy credentials first.
        if let proxySettings = backendConfig.proxySettings, proxySettings.needsAuthentication {
            router.presentSheet(
                RootView.ModalDestination.onPremiseLogin(
                    email: email,
                    environment: backendConfig,
                    backendMetadata: nil
                )
            )
        } else {
            // Before we can make requests we need to resolve the api version.
            let backendMetadata: BackendMetadata
            do {
                backendMetadata = try await resolveBackendMetadata()
            } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
                alert = .noInternet
            } catch  {
                alert = .unknownError
                WireLogger.authentication.error("Unexpected error while fetching default SSO code: \(error)")
            }

            do {
                if let ssoURL = try await fetchSSOURL(apiVersion: backendMetadata.apiVersion) {
                    router.presentSheet(
                        RootView.ModalDestination.ssoLogin(
                            url: ssoURL,
                            BackendMetadata: backendMetadata
                        )
                    )
                } else {
                    router.presentSheet(
                        RootView.ModalDestination.onPremiseLogin(
                            email: email,
                            environment: backendConfig,
                            backendMetadata: backendMetadata
                        )
                    )
                }
            } catch {
                WireLogger.authentication.error("Unexpected error while fetching default SSO code: \(error)")
                alert = .unknownError
            }
        }
    }

    private func resolveBackendMetadata() async throws -> BackendMetadata {
        let useCase = factory.resolveBackendMetadataUseCase()
        return try await Task.detached {
            try await useCase.invoke()
        }.value
    }

    private func fetchSSOURL(apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion) async throws -> URL? {
        let useCase = factory.fetchSSOURLUseCase(apiVersion: apiVersion)
        return try await Task.detached {
            try await useCase.invoke()
        }.value
    }

    // MARK: - Model

    package struct ItemUIModel {
        let title: String
        let value: String
        let isURL: Bool
    }

}

// MARK: Alerts

package extension SwitchBackendConfirmationViewModel {

    struct Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        let title: String
        let message: String

        private typealias Title = L10n.Authentication.Error.Title
        private typealias Message = L10n.Authentication.Error.Message

        static let unknownError = Alert(title: Title.general, message: Message.general)
        static let noInternet = Alert(title: Title.noInternet, message: Message.noInternet)
    }

}
