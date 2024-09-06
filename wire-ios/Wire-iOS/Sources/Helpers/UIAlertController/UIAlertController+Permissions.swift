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

import UIKit
import WireCommonComponents

extension UIAlertController {

    class func cameraPermissionAlert(completion: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        permissionAlert(
            title: L10n.Localizable.Voice.Alert.CameraWarning.title,
            message: "NSCameraUsageDescription".infoPlistLocalized,
            completion: completion
        )
    }

    class var microphonePermissionAlert: UIAlertController {
        permissionAlert(
            title: L10n.Localizable.Voice.Alert.MicrophoneWarning.title,
            message: "NSMicrophoneUsageDescription".infoPlistLocalized
        )
    }

    class var photoLibraryPermissionAlert: UIAlertController {
        permissionAlert(
            title: L10n.Localizable.Library.Alert.PermissionWarning.title,
            message: L10n.Localizable.Library.Alert.PermissionWarning.NotAllowed.explaination
        )
    }

    private class func permissionAlert(
        title: String,
        message: String,
        completion: ((UIAlertAction) -> Void)? = nil
    ) -> UIAlertController {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.later,
            style: .cancel,
            handler: { action in
                completion?(action)
            }
        ))
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.openSettings,
            style: .default,
            handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
                completion?(action)
            }
        ))

        return alert
    }
}
