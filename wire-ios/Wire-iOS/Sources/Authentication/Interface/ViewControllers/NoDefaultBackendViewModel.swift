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
import WireLogging
import WireSyncEngine
import WireTransport

protocol NoDefaultBackendViewModelDelegate: AnyObject {
    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didChangeLoading isLoading: Bool)
    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didFailWithMessage message: String)
    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didConfigureBackend configurationURL: URL)
    func noDefaultBackendViewModel(
        _ viewModel: NoDefaultBackendViewModel,
        requestUserConfirmationForBackendSwitch environment: BackendEnvironment,
        didConfirm: @escaping (Bool) -> Void
    )
}

/// The subset of `SessionManager` behavior that `NoDefaultBackendViewModel` needs.
/// Exists so tests can substitute a lightweight double for the real (non-mockable) `SessionManager`.
/// sourcery: AutoMockable
protocol BackendConfigurationSessionManaging: AnyObject {
    func fetchBackendEnvironment(at url: URL, completion: @escaping (Result<BackendEnvironment, Error>) -> Void)
    func markNetworkSessionsAsReady(_ ready: Bool)
    func switchBackendWithoutResolving(to environment: BackendEnvironment)
}

extension SessionManager: BackendConfigurationSessionManaging {}

/// Validates a backend configuration link (typed or scanned) and, once valid,
/// fetches and applies the corresponding backend environment.
final class NoDefaultBackendViewModel {

    weak var delegate: NoDefaultBackendViewModelDelegate?

    private let sessionManager: () -> BackendConfigurationSessionManaging?

    init(sessionManager: @escaping () -> BackendConfigurationSessionManaging? = { SessionManager.shared }) {
        self.sessionManager = sessionManager
    }

    func submitConfigurationLink(_ rawInput: String) {
        guard let sessionManager = sessionManager() else {
            fail()
            return
        }

        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            fail()
            return
        }

        guard let url = URL(string: trimmed) else {
            fail()
            return
        }

        var configurationURL: URL?
        if let action = try? URLAction(url: url), case let .accessBackend(configURL) = action {
            configurationURL = configURL
        } else if url.scheme == "https" || url.scheme == "http" {
            // assume we have the configurationURL already
            configurationURL = url
        }

        guard let configurationURL else {
            fail()
            return
        }

        delegate?.noDefaultBackendViewModel(self, didChangeLoading: true)

        sessionManager.fetchBackendEnvironment(at: configurationURL) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(backendEnvironment):
                delegate?
                    .noDefaultBackendViewModel(
                        self,
                        requestUserConfirmationForBackendSwitch: backendEnvironment
                    ) { didConfirm in
                        defer { self.delegate?.noDefaultBackendViewModel(self, didChangeLoading: false) }
                        guard didConfirm else { return }
                        sessionManager.markNetworkSessionsAsReady(true)
                        sessionManager.switchBackendWithoutResolving(to: backendEnvironment)
                        // persist backendenvironment so urls work
                        backendEnvironment.save(in: .applicationGroup)
                        self.delegate?.noDefaultBackendViewModel(self, didConfigureBackend: configurationURL)
                    }
            case .failure:
                delegate?.noDefaultBackendViewModel(self, didChangeLoading: false)
                fail()
            }
        }
    }

    private func fail() {
        delegate?.noDefaultBackendViewModel(self, didFailWithMessage: L10n.Localizable.NoDefaultBackend.error)
    }
}
