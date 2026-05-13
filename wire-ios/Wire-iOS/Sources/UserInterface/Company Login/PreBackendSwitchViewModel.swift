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

final class PreBackendSwitchViewModel {

    // MARK: - State

    struct State: Equatable {

        let title: String
        let subtitle: String
        let information: String
        let progressDuration: TimeInterval

    }

    let state: State

    // MARK: - Life cycle

    private let backendURL: URL?
    private let didComplete: (URL) -> Void

    init(
        backendURL: URL? = nil,
        title: String = L10n.Localizable.Login.Sso.BackendSwitch.title,
        subtitle: String = L10n.Localizable.Login.Sso.BackendSwitch.subtitle,
        information: String = L10n.Localizable.Login.Sso.BackendSwitch.information,
        progressDuration: TimeInterval = 5,
        didComplete: @escaping (URL) -> Void = { _ in }
    ) {
        self.backendURL = backendURL
        self.state = State(
            title: title,
            subtitle: subtitle,
            information: information,
            progressDuration: progressDuration
        )
        self.didComplete = didComplete
    }

    // MARK: - Actions

    enum Action {

        case timerCompleted

    }

    // MARK: - Backend decision

    enum BackendDecision: Equatable {

        case switchTo(URL)
        case unavailable

    }

    func backendDecision() -> BackendDecision {
        guard let backendURL else {
            return .unavailable
        }

        return .switchTo(backendURL)
    }

    // MARK: - Routing

    enum Route: Equatable {

        case complete(URL)
        case none

    }

    func handleAction(_ action: Action) -> Route {
        switch action {
        case .timerCompleted:
            switch backendDecision() {
            case let .switchTo(url):
                return .complete(url)

            case .unavailable:
                return .none
            }
        }
    }

    func complete(route: Route) {
        switch route {
        case let .complete(url):
            didComplete(url)

        case .none:
            break
        }
    }

}
