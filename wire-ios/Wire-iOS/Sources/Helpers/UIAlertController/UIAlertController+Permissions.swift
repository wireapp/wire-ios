//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import WireCommonComponents

extension UIAlertController {

    class func cameraPermissionAlert(with completion: AlertActionHandler? = nil) -> UIAlertController {
        return permissionAlert(
            title: L10n.Localizable.Voice.Alert.CameraWarning.title,
            message: "NSCameraUsageDescription".infoPlistLocalized,
            completion: completion
        )
    }

    class var microphonePermissionAlert: UIAlertController {
        return permissionAlert(
            title: L10n.Localizable.Voice.Alert.MicrophoneWarning.title,
            message: "NSMicrophoneUsageDescription".infoPlistLocalized
        )
    }

    class var photoLibraryPermissionAlert: UIAlertController {
        return permissionAlert(
            title: L10n.Localizable.Library.Alert.PermissionWarning.title,
            message: L10n.Localizable.Library.Alert.PermissionWarning.NotAllowed.explaination
        )
    }

    private class func permissionAlert(
        title: String,
        message: String,
        completion: AlertActionHandler? = nil
    ) -> UIAlertController {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(.actionLater(with: completion))
        alert.addAction(.actionSettings(with: completion))

        return alert
    }
}

extension UIAlertAction {

    typealias GeneralLocale = L10n.Localizable.General

    class func actionLater(with completion: AlertActionHandler?) -> UIAlertAction {
        return UIAlertAction(
            title: GeneralLocale.later,
            style: .cancel,
            handler: { action in
                completion?(action)
            })
    }

    class func actionSettings(with completion: AlertActionHandler?) -> UIAlertAction {
        return UIAlertAction(
            title: GeneralLocale.openSettings,
            style: .default,
            handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
                completion?(action)
            })
    }
}
