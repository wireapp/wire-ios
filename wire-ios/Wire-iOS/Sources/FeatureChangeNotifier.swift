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

import Combine
import UIKit
import WireDataModel
import WireDomain
import WireSyncEngine

protocol FeatureChangeAlertPresenting: AnyObject {
    func present(_ alert: UIAlertController)
}

/// Presents alerts for feature-config changes (e2ei, file sharing,
/// self-deleting messages, conversation guest links), sourced from the
/// `UserSession.observeFeatureStates()` publisher.

final class FeatureChangeNotifier {

    // MARK: - Private Property

    private let userSession: UserSession
    private let handlers: [Feature.Name: any FeatureChangeHandler]
    private let defaultHandler: any FeatureChangeHandler = DefaultFeatureChangeHandler()

    private var featureStateCancellable: AnyCancellable?

    weak var presenter: FeatureChangeAlertPresenting?

    // MARK: - Init

    init(
        userSession: UserSession,
        handlers: [Feature.Name: any FeatureChangeHandler] = [:]
    ) {
        self.userSession = userSession
        self.handlers = handlers

        self.featureStateCancellable = userSession.observeFeatureStates()
            .filter(\.needsToNotifyUser)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] featureState in
                self?.notifyFeatureStateChange(featureState)
            }
    }

    // MARK: - Private Method

    private func notifyFeatureStateChange(_ featureState: FeatureState) {
        Task {
            await present(featureState: featureState, acknowledger: self)
        }
    }

    @MainActor
    private func present(
        featureState: FeatureState,
        acknowledger: FeatureChangeAcknowledger
    ) async {
        let handler = handlers[featureState.name] ?? defaultHandler
        guard let alert = await handler.alert(for: featureState, acknowledger: acknowledger) else { return }
        presenter?.present(alert)
    }
}

// MARK: - FeatureChangeAcknowledger

extension FeatureChangeNotifier: FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name) {
        Task { [weak self] in
            await self?.userSession.acknowledgeFeatureChange(for: featureName)
        }
    }
}
