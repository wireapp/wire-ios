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

import Photos
import UIKit
import WireCommonComponents

extension UIApplication {

    class func wr_requestOrWarnAboutMicrophoneAccess(
        alertPresenter: UIViewController,
        _ grantedHandler: @escaping (_ granted: Bool) -> Void
    ) {
        let audioPermissionsWereNotDetermined = AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined

        AVAudioSession.sharedInstance().requestRecordPermission { granted in

            DispatchQueue.main.async {
                if !granted {
                    self.wr_warnAboutMicrophonePermission(alertPresenter: alertPresenter)
                }

                if audioPermissionsWereNotDetermined && granted {
                    NotificationCenter.default.post(name: Notification.Name.UserGrantedAudioPermissions, object: nil)
                }
                grantedHandler(granted)
            }
        }
    }

    class func wr_requestOrWarnAboutVideoAccess(
        alertPresenter: UIViewController,
        _ grantedHandler: @escaping (_ granted: Bool) -> Void
    ) {
        UIApplication.wr_requestVideoAccess({ granted in
            DispatchQueue.main.async(execute: {
                if !granted {
                    self.wr_warnAboutCameraPermission(alertPresenter: alertPresenter) { _ in
                        grantedHandler(granted)
                    }
                } else {
                    grantedHandler(granted)
                }
            })
        })
    }

    static func wr_requestOrWarnAboutPhotoLibraryAccess(
        alertPresenter: UIViewController,
        _ grantedHandler: @escaping (Bool) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .restricted:
                    self.wr_warnAboutPhotoLibraryRestricted(alertPresenter: alertPresenter)
                    grantedHandler(false)
                case .denied,
                     .notDetermined:
                    self.wr_warnAboutPhotoLibaryDenied(alertPresenter: alertPresenter)
                    grantedHandler(false)
                case .authorized:
                    grantedHandler(true)
                case .limited:
                    fallthrough
                @unknown default:
                    break
                }
            }
        }
    }

    class func wr_requestVideoAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            DispatchQueue.main.async(execute: {
                grantedHandler(granted)
            })
        })
    }

    private class func wr_warnAboutCameraPermission(
        alertPresenter: UIViewController,
        completion: @escaping (UIAlertAction) -> Void
    ) {
        let currentResponder = UIResponder.currentFirst as? UIView
        currentResponder?.endEditing(true)

        let alert = UIAlertController.cameraPermissionAlert(completion: completion)
        alertPresenter.present(alert, animated: true)
    }

    private class func wr_warnAboutMicrophonePermission(alertPresenter: UIViewController) {
        let alert = UIAlertController.microphonePermissionAlert
        alertPresenter.present(alert, animated: true)
    }

    private class func wr_warnAboutPhotoLibraryRestricted(alertPresenter: UIViewController) {
        let alert = UIAlertController(
            title: L10n.Localizable.Library.Alert.PermissionWarning.title,
            message: L10n.Localizable.Library.Alert.PermissionWarning.Restrictions.explaination,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))
        alertPresenter.present(alert, animated: true)
    }

    private class func wr_warnAboutPhotoLibaryDenied(alertPresenter: UIViewController) {
        let alert = UIAlertController.photoLibraryPermissionAlert
        alertPresenter.present(alert, animated: true)
    }
}
