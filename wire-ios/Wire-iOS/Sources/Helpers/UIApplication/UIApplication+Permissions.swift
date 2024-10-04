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

extension UIApplication: ApplicationProtocol {

    class func wr_requestOrWarnAboutMicrophoneAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        let audioPermissionsWereNotDetermined = AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined

        AVAudioSession.sharedInstance().requestRecordPermission { granted in

            DispatchQueue.main.async {
                if !granted {
                    self.wr_warnAboutMicrophonePermission()
                }

                if audioPermissionsWereNotDetermined && granted {
                    NotificationCenter.default.post(name: Notification.Name.UserGrantedAudioPermissions, object: nil)
                }
                grantedHandler(granted)
            }
        }
    }

    class func wr_requestOrWarnAboutVideoAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        UIApplication.wr_requestVideoAccess { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.wr_warnAboutCameraPermission { _ in
                        grantedHandler(granted)
                    }
                } else {
                    grantedHandler(granted)
                }
            }
        }
    }

    static func wr_requestOrWarnAboutPhotoLibraryAccess(_ grantedHandler: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .restricted:
                    self.wr_warnAboutPhotoLibraryRestricted()
                    grantedHandler(false)
                case .denied,
                     .notDetermined:
                    self.wr_warnAboutPhotoLibaryDenied()
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
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                grantedHandler(granted)
            }
        }
    }

    private class func wr_warnAboutCameraPermission(withCompletion completion: ((UIAlertAction) -> Void)?) {
        let currentResponder = UIResponder.currentFirst
        (currentResponder as? UIView)?.endEditing(true)

        let alert = UIAlertController.cameraPermissionAlert(completion: completion)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let rootViewController = appDelegate.mainWindow.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private class func wr_warnAboutMicrophonePermission() {
        let alert = UIAlertController.microphonePermissionAlert

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let rootViewController = appDelegate.mainWindow.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private class func wr_warnAboutPhotoLibraryRestricted() {
        let alert = UIAlertController(
            title: L10n.Localizable.Library.Alert.PermissionWarning.title,
            message: L10n.Localizable.Library.Alert.PermissionWarning.Restrictions.explaination,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let rootViewController = appDelegate.mainWindow.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private class func wr_warnAboutPhotoLibaryDenied() {
        let alert = UIAlertController.photoLibraryPermissionAlert

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let rootViewController = appDelegate.mainWindow.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}
