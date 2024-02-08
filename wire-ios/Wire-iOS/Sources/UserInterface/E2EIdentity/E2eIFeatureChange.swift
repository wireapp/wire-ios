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

enum E2eIChangeAction: CaseIterable {
    case getCertificate, remindLater
}

extension UIAlertController {

    static func alertForE2eIChangeWithActions(handler: @escaping (E2eIChangeAction) -> Void) -> UIAlertController {

        typealias MlsE2eiStrings = L10n.Localizable.FeatureConfig.Alert.MlsE2ei

        let controller = UIAlertController(
            title: MlsE2eiStrings.title,
            message: MlsE2eiStrings.message,
            preferredStyle: .alert
        )

        let topViewController = UIApplication.shared.topmostViewController(onlyFullScreen: true)

        let learnMoreAction = UIAlertAction.link(title: L10n.Localizable.FeatureConfig.Alert.MlsE2ei.Button.learnMore,
                                                 url: URL.wr_e2eiLearnMore,
                                                 presenter: topViewController)
        let getCertificateAction = UIAlertAction(title: L10n.Localizable.FeatureConfig.Alert.MlsE2ei.Button.getCertificate,
                                                 style: .default) {_ in
            handler(.getCertificate)
        }
        let remindLaterAction = UIAlertAction(title: L10n.Localizable.FeatureConfig.Alert.MlsE2ei.Button.remindMeLater,
                                              style: .destructive) {_ in
            handler(.remindLater)
        }

        controller.addAction(learnMoreAction)
        controller.addAction(getCertificateAction)
        controller.addAction(remindLaterAction)

        return controller
    }

}
