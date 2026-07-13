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

import AVFoundation
import PhotosUI
import UIKit
import WireLogging
import WireSyncEngine

extension ConversationInputBarViewController {

    func presentImagePicker(
        sourceType: UIImagePickerController.SourceType,
        mediaTypes: [String],
        allowsEditing: Bool,
        preSelectedAssetIdentifiers: [String] = [],
        pointToView: UIView
    ) {

        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            if UIDevice.isSimulator {
                let testFilePath = "/var/tmp/video.mp4"
                if FileManager.default.fileExists(atPath: testFilePath) {
                    uploadFiles(at: [URL(fileURLWithPath: testFilePath)])
                }
            }
            return
                // Don't crash on Simulator
        }

        let presentController = { [self] in
            // Allows multiple media selection on Wire drive conversations.
            if useWireDrive(), sourceType != .camera {
                // As per Apple's doc, we shouldn't use the empty initializer if we need the asset identifiers to be
                // non-nil.
                var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
                config.selectionLimit = 0
                config.preselectedAssetIdentifiers = preSelectedAssetIdentifiers
                config.filter = .any(of: [.images, .videos])

                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                present(picker, animated: true)
            } else {
                let pickerController = UIImagePickerController()
                pickerController.sourceType = sourceType
                pickerController.preferredContentSize = .IPadPopover.preferredContentSize
                pickerController.delegate = self
                pickerController.allowsEditing = allowsEditing
                pickerController.mediaTypes = mediaTypes
                pickerController.videoMaximumDuration = userSession.maxVideoLength
                pickerController.videoExportPreset = AVURLAsset.defaultVideoQuality
                if sourceType == .camera {
                    let settingsCamera: SettingsCamera? = Settings.shared[.preferredCamera]
                    pickerController.cameraDevice = settingsCamera == .back ? .rear : .front
                }

                if sourceType != .camera,
                   let popoverPresentationController = pickerController.popoverPresentationController {
                    popoverPresentationController.sourceView = pointToView.superview
                    popoverPresentationController.sourceRect = pointToView.frame
                    popoverPresentationController.backgroundColor = .white
                    popoverPresentationController.permittedArrowDirections = .down
                }

                present(pickerController, animated: true)
            }
        }

        if sourceType == .camera {
            execute(videoPermissions: presentController)
        } else {
            presentController()
        }
    }

    func processVideo(
        info: [UIImagePickerController.InfoKey: Any],
        picker: UIImagePickerController
    ) {
        guard let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            parent?.dismiss(animated: true)
            WireLogger.ui.error("Video not provided from \(picker): info \(info)")
            return
        }
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let videoTempURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent(String.filename(for: selfUser))
            .appendingPathExtension(videoURL.pathExtension)

        do {
            try FileManager.default.removeTmpIfNeededAndCopy(fileURL: videoURL, tmpURL: videoTempURL)
        } catch {
            WireLogger.ui.error("Cannot copy video from \(videoURL) to \(videoTempURL): \(error)")
            return
        }

        if picker.sourceType == UIImagePickerController.SourceType.camera,
           UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoTempURL.path),
           mediaShareRestrictionManager.hasAccessToCameraRoll {
            UISaveVideoAtPathToSavedPhotosAlbum(
                videoTempURL.path,
                self,
                #selector(video(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }

        AVURLAsset
            .convertVideoToUploadFormat(
                at: videoTempURL,
                fileLengthLimit: Int64(userSession.maxUploadFileSize)
            ) { resultURL, _, error in
                if error == nil,
                   let resultURL {
                    self.uploadFiles(at: [resultURL])
                }

                self.parent?.dismiss(animated: true)
            }
    }

}
