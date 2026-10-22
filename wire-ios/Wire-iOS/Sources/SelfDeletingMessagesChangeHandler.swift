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

import UIKit
import WireDataModel
import WireDomain
import WireSyncEngine

/// Handles self-deleting-messages changes specifically, since the alert copy
/// depends on the team's enforced timeout.
struct SelfDeletingMessagesChangeHandler: FeatureChangeHandler {

    private typealias Strings = L10n.Localizable.FeatureConfig

    let userSession: UserSession

    @MainActor
    func alert(
        for featureState: FeatureState,
        acknowledger: FeatureChangeAcknowledger
    ) async -> UIAlertController? {
        guard featureState.name == .selfDeletingMessages else { return nil }
        guard let message = message(for: featureState) else { return nil }

        return UIAlertController.alertForFeatureChange(message: message) {
            acknowledger.acknowledgeChange(for: .selfDeletingMessages)
        }
    }

    private func message(for featureState: FeatureState) -> String? {
        guard featureState.isEnabled else { return Strings.Alert.SelfDeletingMessages.Message.disabled }

        let enforcedTimeout = userSession.selfDeletingMessagesFeature.config.enforcedTimeoutSeconds
        guard enforcedTimeout > 0 else { return Strings.Alert.SelfDeletingMessages.Message.enabled }

        let timeout = MessageDestructionTimeoutValue(rawValue: TimeInterval(enforcedTimeout))
        guard let timeoutString = timeout.displayString else { return nil }

        return Strings.Alert.SelfDeletingMessages.Message.forcedOn(timeoutString)
    }
}
