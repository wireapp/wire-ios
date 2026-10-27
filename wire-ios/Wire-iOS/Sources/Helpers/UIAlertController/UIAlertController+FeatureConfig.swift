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

protocol FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name)

}

extension LegacyFeatureRepository: FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name) {
        setNeedsToNotifyUser(false, for: featureName)
    }

}

extension UIAlertController {

    private typealias Strings = L10n.Localizable.FeatureConfig

    static func alertForFeatureChange(
        message: String,
        onOK: @escaping () -> Void
    ) -> UIAlertController {

        let alert = UIAlertController(
            title: Strings.Alert.genericTitle,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default,
            handler: { _ in onOK() }
        ))

        return alert
    }
}
