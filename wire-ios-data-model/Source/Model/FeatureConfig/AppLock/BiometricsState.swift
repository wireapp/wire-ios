//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - BiometricsStateProtocol

// sourcery: AutoMockable
protocol BiometricsStateProtocol {
    func biometricsChanged(in context: AuthenticationContextProtocol) -> Bool
    func persistState()
}

// MARK: - BiometricsState

final class BiometricsState: BiometricsStateProtocol {
    // MARK: Internal

    var currentPolicyDomainState: Data?

    var lastPolicyDomainState: Data? {
        get {
            UserDefaults.standard.data(forKey: UserDefaultsDomainStateKey)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsDomainStateKey)
        }
    }

    /// Returns `true` if the biometrics database has changed, e.g if finger prints are
    /// added or removed.

    func biometricsChanged(in context: AuthenticationContextProtocol) -> Bool {
        currentPolicyDomainState = context.evaluatedPolicyDomainState
        guard let lastState = lastPolicyDomainState else {
            return false
        }
        return currentPolicyDomainState != lastState
    }

    /// Persists the last seen biometrics state for future comparisons.

    func persistState() {
        lastPolicyDomainState = currentPolicyDomainState
    }

    // MARK: Private

    private let UserDefaultsDomainStateKey = "DomainStateKey"
}
