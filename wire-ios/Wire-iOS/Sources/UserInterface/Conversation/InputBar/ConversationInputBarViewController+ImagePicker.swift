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

import AVFoundation
import UIKit
import WireSyncEngine

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController - Image Picker")

extension ConversationInputBarViewController {

    func presentImagePicker(
        sourceType: UIImagePickerController.SourceType,
        mediaTypes: [String],
        allowsEditing: Bool,
        pointToView: UIView
    ) {

        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            if UIDevice.isSimulator {
                let testFilePath = "/var/tmp/video.mp4"
                if FileManager.default.fileExists(atPath: testFilePath) {
                    uploadFile(at: URL(fileURLWithPath: testFilePath))
                }
            }
            return
            // Don't crash on Simulator
        }

        let presentController = { [self] in

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

            if sourceType != .camera, let popoverPresentationController = pickerController.popoverPresentationController {
                popoverPresentationController.sourceView = pointToView.superview
                popoverPresentationController.sourceRect = pointToView.frame
                popoverPresentationController.backgroundColor = .white
                popoverPresentationController.permittedArrowDirections = .down
            }

            present(pickerController, animated: true)
        }

        if sourceType == .camera {
            execute(videoPermissions: presentController)
        } else {
            presentController()
        }
    }

    func processVideo(info: [UIImagePickerController.InfoKey: Any],
                      picker: UIImagePickerController) {
        guard let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            parent?.dismiss(animated: true)
            zmLog.error("Video not provided form \(picker): info \(info)")
            return
        }
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let videoTempURL = URL(fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true).appendingPathComponent(String.filename(for: selfUser)).appendingPathExtension(videoURL.pathExtension)

        do {
            try FileManager.default.removeTmpIfNeededAndCopy(fileURL: videoURL, tmpURL: videoTempURL)
        } catch {
            zmLog.error("Cannot copy video from \(videoURL) to \(videoTempURL): \(error)")
            return
        }

        if picker.sourceType == UIImagePickerController.SourceType.camera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoTempURL.path),
           MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).hasAccessToCameraRoll {
            UISaveVideoAtPathToSavedPhotosAlbum(videoTempURL.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        }

        AVURLAsset.convertVideoToUploadFormat(at: videoTempURL, fileLengthLimit: Int64(userSession.maxUploadFileSize)) { resultURL, _, error in
            if error == nil,
               let resultURL {
                self.uploadFile(at: resultURL)
            }

            self.parent?.dismiss(animated: true)
        }
    }

}
