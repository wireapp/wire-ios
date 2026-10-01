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
/// self-deleting messages, conversation guest links), sourced from either
/// the legacy `.featureDidChangeNotification` or the new
/// `UserSession.observeFeatureStates()` publisher.

final class FeatureChangeNotifier {

    // MARK: - Private Property

    private let notificationCenter: NotificationCenter
    private let userSession: UserSession
    private let featureRepositoryProvider: any LegacyFeatureRepositoryProvider
    private let handlers: [Feature.Name: any FeatureChangeHandler]
    private let defaultHandler: any FeatureChangeHandler = DefaultFeatureChangeHandler()

    private var featureChangeObserverToken: Any?
    private var featureStateCancellable: AnyCancellable?

    weak var presenter: FeatureChangeAlertPresenting?

    // MARK: - Init

    init(
        notificationCenter: NotificationCenter,
        userSession: UserSession,
        featureRepositoryProvider: any LegacyFeatureRepositoryProvider,
        handlers: [Feature.Name: any FeatureChangeHandler] = [:]
    ) {
        self.notificationCenter = notificationCenter
        self.userSession = userSession
        self.featureRepositoryProvider = featureRepositoryProvider
        self.handlers = handlers

        self.featureChangeObserverToken = notificationCenter.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.notifyFeatureChange(notification)
        }

        self.featureStateCancellable = userSession.observeFeatureStates()
            .filter(\.needsToNotifyUser)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] featureState in
                self?.notifyFeatureStateChange(featureState)
            }
    }

    deinit {
        if let featureChangeObserverToken {
            notificationCenter.removeObserver(featureChangeObserverToken)
        }
    }

    // MARK: - Private Method

    private func notifyFeatureChange(_ note: Notification) {
        guard let change = note.object as? LegacyFeatureRepository.FeatureChange else { return }
        Task {
            await present(featureState: change.featureState, acknowledger: featureRepositoryProvider.featureRepository)
        }
    }

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

// MARK: - LegacyFeatureRepositoryProvider

protocol LegacyFeatureRepositoryProvider {
    var featureRepository: LegacyFeatureRepository { get }
}

extension ZMUserSession: LegacyFeatureRepositoryProvider {}
