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

/// Decides how to react to a given feature's state, e.g. whether to present
/// an alert (and which one) or silently acknowledge it. Features with no
/// custom handling fall back to `DefaultFeatureChangeHandler`.
protocol FeatureChangeHandler {
    @MainActor
    func alert(
        for featureState: FeatureState,
        acknowledger: FeatureChangeAcknowledger
    ) async -> UIAlertController?
}

struct DefaultFeatureChangeHandler: FeatureChangeHandler {

    private typealias Strings = L10n.Localizable.FeatureConfig

    @MainActor
    func alert(
        for featureState: FeatureState,
        acknowledger: FeatureChangeAcknowledger
    ) async -> UIAlertController? {
        guard let message = message(for: featureState) else { return nil }
        return UIAlertController.alertForFeatureChange(message: message) {
            acknowledger.acknowledgeChange(for: featureState.name)
        }
    }

    private func message(for featureState: FeatureState) -> String? {
        switch featureState.name {
        case .fileSharing:
            return featureState.isEnabled
                ? Strings.Update.FileSharing.Alert.Message.enabled
                : Strings.Update.FileSharing.Alert.Message.disabled

        case .conversationGuestLinks:
            return featureState.isEnabled
                ? Strings.Alert.ConversationGuestLinks.Message.enabled
                : Strings.Alert.ConversationGuestLinks.Message.disabled

        default:
            return nil
        }
    }
}
