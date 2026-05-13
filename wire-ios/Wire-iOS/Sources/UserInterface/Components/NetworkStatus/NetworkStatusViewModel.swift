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

import WireSyncEngine

final class NetworkStatusViewModel {

    typealias Localizable = L10n.Localizable.SystemStatusBar.NoInternet

    enum HorizontalSizeClass: Equatable {
        case compact
        case regular
        case unspecified
    }

    struct AlertContent: Equatable {
        let title: String
        let message: String
    }

    enum Route: Equatable {
        case offlineAlert(AlertContent)
        case none
    }

    private(set) var pendingState: NetworkStatusViewState?
    private(set) var currentState: NetworkStatusViewState = .online

    var offlineAlert: AlertContent {
        AlertContent(
            title: Localizable.title,
            message: Localizable.explanation
        )
    }

    func viewState(from networkState: NetworkState) -> NetworkStatusViewState {
        switch networkState {
        case .offline:
            .offlineExpanded
        case .online:
            .online
        case .onlineSynchronizing:
            .onlineSynchronizing
        }
    }

    func enqueue(state: NetworkStatusViewState) {
        pendingState = state
    }

    func applyPendingState() -> NetworkStatusViewState? {
        guard let pendingState else { return nil }

        currentState = pendingState
        self.pendingState = nil

        return currentState
    }

    func update(state: NetworkStatusViewState) {
        currentState = state
    }

    func stateToEnqueueWhenApplicationBecomesActive() -> NetworkStatusViewState {
        pendingState ?? currentState
    }

    func routeForTap(on state: NetworkStatusViewState) -> Route {
        switch state {
        case .offlineExpanded:
            .offlineAlert(offlineAlert)
        case .online, .onlineSynchronizing:
            .none
        }
    }

    func shouldApplyState(
        isIPadRegular: Bool,
        delegateAllowsDisplay: Bool
    ) -> Bool {
        !isIPadRegular || delegateAllowsDisplay
    }

    func visibleStateForIPadTraitChange(
        horizontalSizeClass: HorizontalSizeClass,
        delegateAllowsDisplay: Bool
    ) -> NetworkStatusViewState {
        switch horizontalSizeClass {
        case .regular:
            delegateAllowsDisplay ? currentState : .online
        case .compact, .unspecified:
            currentState
        }
    }
}
