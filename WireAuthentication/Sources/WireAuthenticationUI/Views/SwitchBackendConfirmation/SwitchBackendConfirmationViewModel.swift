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
public class SwitchBackendConfirmationViewModel: ObservableObject {

    package enum ModalDestination: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case ssoLogin(url: URL)
    }

    private typealias Strings = L10n.SwitchBackendConfirmation

    // MARK: - State

    let items: [ItemUIModel]

    private let router: any Router
    private let email: String
    private let environment: BackendConfig
    private let fetchDefaultSSOSettings: any FetchDefaultSSOSettingsUseCaseProtocol
    private let ssoLinkGenerator: SSOLinkGeneratorProtocol

    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: ModalDestination?

    // MARK: - Life cycle

    public init(
        router: any Router,
        email: String,
        fetchDefaultSSOSettings: any FetchDefaultSSOSettingsUseCaseProtocol,
        ssoLinkGenerator: SSOLinkGeneratorProtocol,
        environment: BackendConfig
    ) {
        self.router = router
        self.email = email
        self.environment = environment
        self.fetchDefaultSSOSettings = fetchDefaultSSOSettings
        self.ssoLinkGenerator = ssoLinkGenerator
        self.items = [
            ItemUIModel(title: Strings.backendName, value: environment.title, isURL: false),
            ItemUIModel(title: Strings.backendUrl, value: environment.endpoints.backendURL.absoluteString, isURL: true),
            ItemUIModel(
                title: Strings.backendWsurl,
                value: environment.endpoints.backendWSURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(
                title: Strings.blacklistUrl,
                value: environment.endpoints.blackListURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(title: Strings.teamsUrl, value: environment.endpoints.teamsURL.absoluteString, isURL: true),
            ItemUIModel(
                title: Strings.accountsUrl,
                value: environment.endpoints.accountsURL.absoluteString,
                isURL: true
            ),
            ItemUIModel(title: Strings.websiteUrl, value: environment.endpoints.websiteURL.absoluteString, isURL: true)
        ]
    }

    func confirm() async {
        isLoading = true

        let task = Task.detached { [fetchDefaultSSOSettings] () -> URL? in
            guard let ssoCode = try await fetchDefaultSSOSettings.invoke() else {
                return nil
            }

            return try await self.ssoLinkGenerator.generateSSOLink(ssoCode: ssoCode)
        }

        do {
            let url = try await task.value
            if let url {
                modalDestination = .ssoLogin(url: url)
            } else {
                router.presentSheet(
                    RootView.ModalDestination.onPremiseLogin(
                        email: email,
                        environment: environment
                    )
                )
            }
        } catch {
            await MainActor.run {
                self.alert = .unknownError
            }
            WireLogger.authentication.error("Unexpected error while fetching default SSO code: \(error)")
        }

        isLoading = false
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
    }

}
