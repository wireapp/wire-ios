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
import WireDataModel
import WireDomain

public extension UserSession {

    /// Observes feature config state changes as they're discovered, whether through
    /// periodic sync or live push events.

    func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        guard let clientSessionComponent else {
            return Empty().eraseToAnyPublisher()
        }

        return clientSessionComponent.featureConfigRepository.observeFeatureStates()
    }

    /// Acknowledges that the user has been notified about a feature's current state,
    /// so the same state won't be flagged as needing notification again.
    /// - parameter name: The name of the feature.

    func acknowledgeFeatureChange(for name: Feature.Name) async {
        guard let clientSessionComponent else {
            return
        }

        await clientSessionComponent.featureConfigRepository.acknowledgeFeatureChange(for: name)
    }

}
