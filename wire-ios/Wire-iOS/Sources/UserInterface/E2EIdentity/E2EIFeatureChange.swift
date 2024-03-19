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
import WireSyncEngine

enum E2EIChangeAction: CaseIterable {
    case getCertificate, remindLater
}

extension UIAlertController {
    private typealias MlsE2EIStrings = L10n.Localizable.FeatureConfig.Alert.MlsE2ei

    static func alertForE2eIChangeWithActions(
        title: String = MlsE2EIStrings.title,
        message: String = MlsE2EIStrings.message,
        enrollButtonText: String = MlsE2EIStrings.Button.getCertificate,
        canRemindLater: Bool = true,
        handler: @escaping (E2EIChangeAction) -> Void) -> UIAlertController {

        let controller = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let topViewController = UIApplication.shared.topmostViewController(onlyFullScreen: true)

        let learnMoreAction = UIAlertAction.link(
            title: MlsE2EIStrings.Button.learnMore,
            url: URL.wr_e2eiLearnMore,
            presenter: topViewController
        ) {
            if !canRemindLater {
                NotificationCenter.default.post(name: .checkForE2EICertificateExpiryStatus, object: nil)
            }
        }
        let getCertificateAction = UIAlertAction(title: enrollButtonText,
                                                 style: .default) {_ in
            handler(.getCertificate)
        }

        controller.addAction(learnMoreAction)
        controller.addAction(getCertificateAction)

        if canRemindLater {
            let remindLaterAction = UIAlertAction(title: MlsE2EIStrings.Button.remindMeLater,
                                                  style: .cancel) {_ in
                handler(.remindLater)
            }
            controller.addAction(remindLaterAction)
        }

        return controller
    }

}
