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
import WireSyncEngine

final class SwitchBackendConfirmationViewModel {

    // MARK: - State

    struct State: Equatable {

        let backendName: String
        let backendURL: String
        let backendWSURL: String
        let blacklistURL: String
        let teamsURL: String
        let accountsURL: String
        let websiteURL: String

    }

    let state: State

    // MARK: - Life cycle

    private let didConfirm: (Bool) -> Void

    convenience init(
        environment: BackendEnvironment,
        didConfirm: @escaping (Bool) -> Void
    ) {
        self.init(
            backendName: environment.title,
            backendURL: environment.backendURL.absoluteString,
            backendWSURL: environment.backendWSURL.absoluteString,
            blacklistURL: environment.blackListURL.absoluteString,
            teamsURL: environment.teamsURL.absoluteString,
            accountsURL: environment.accountsURL.absoluteString,
            websiteURL: environment.websiteURL.absoluteString,
            didConfirm: didConfirm
        )
    }

    init(
        backendName: String,
        backendURL: String,
        backendWSURL: String,
        blacklistURL: String,
        teamsURL: String,
        accountsURL: String,
        websiteURL: String,
        didConfirm: @escaping (Bool) -> Void
    ) {
        self.state = State(
            backendName: backendName,
            backendURL: backendURL,
            backendWSURL: backendWSURL,
            blacklistURL: blacklistURL,
            teamsURL: teamsURL,
            accountsURL: accountsURL,
            websiteURL: websiteURL
        )
        self.didConfirm = didConfirm
    }

    // MARK: - Actions

    enum Action {

        case cancelTapped
        case proceedTapped

    }

    // MARK: - Routing

    enum Route: Equatable {

        case dismiss(confirmed: Bool)

    }

    func handleAction(_ action: Action) -> Route {
        switch action {
        case .cancelTapped:
            return .dismiss(confirmed: false)

        case .proceedTapped:
            return .dismiss(confirmed: true)
        }
    }

    func complete(route: Route) {
        switch route {
        case let .dismiss(confirmed):
            didConfirm(confirmed)
        }
    }

}
