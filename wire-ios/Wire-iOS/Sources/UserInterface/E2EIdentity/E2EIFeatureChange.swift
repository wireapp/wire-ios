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
import WireCommonComponents
import WireSyncEngine

// MARK: - E2EIChangeAction

enum E2EIChangeAction: CaseIterable {
    case getCertificate
    case remindLater
    case learnMore
}

extension UIAlertController {
    private typealias MLSE2EIStrings = L10n.Localizable.FeatureConfig.Alert.MlsE2ei

    static func alertForE2EIChangeWithActions(
        title: String = MLSE2EIStrings.title,
        message: String = MLSE2EIStrings.message,
        enrollButtonText: String = MLSE2EIStrings.Button.getCertificate,
        canRemindLater: Bool = true,
        handler: @escaping (E2EIChangeAction) -> Void
    ) -> UIAlertController {
        let controller = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let topViewController = UIApplication.shared.topmostViewController(onlyFullScreen: true)

        let learnMoreAction = UIAlertAction.link(
            title: MLSE2EIStrings.Button.learnMore,
            url: WireURLs.shared.endToEndIdentityInfo,
            presenter: topViewController
        ) {
            if !canRemindLater {
                NotificationCenter.default.post(name: .checkForE2EICertificateExpiryStatus, object: nil)
            }
            handler(.learnMore)
        }

        let getCertificateAction = UIAlertAction(
            title: enrollButtonText,
            style: .default
        ) { _ in
            handler(.getCertificate)
        }
        let remindLaterAction = UIAlertAction(
            title: MLSE2EIStrings.Button.remindMeLater,
            style: .cancel
        ) { _ in
            handler(.remindLater)
        }

        controller.addAction(learnMoreAction)
        controller.addAction(getCertificateAction)

        if canRemindLater {
            controller.addAction(remindLaterAction)
        }

        return controller
    }
}
