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

import FLAnimatedImage
import MobileCoreServices
import Photos
import WireCommonComponents
import WireLogging
import WireReusableUIComponents
import WireSyncEngine

final class StatusBarVideoEditorController: UIVideoEditorController {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}

extension ConversationInputBarViewController: CameraKeyboardViewControllerDelegate {

    func createCameraKeyboardViewController() -> CameraKeyboardViewController {
        guard let zClientViewController = ZClientViewController.shared else {
            fatal("SplitViewController is not created")
        }
        let splitLayoutObserver = SplitLayoutObserver(zClientViewController: zClientViewController)
        let cameraKeyboardViewController = CameraKeyboardViewController(splitLayoutObservable: splitLayoutObserver)
        cameraKeyboardViewController.delegate = self
        self.cameraKeyboardViewController = cameraKeyboardViewController
        return cameraKeyboardViewController
    }

    func cameraKeyboardViewController(
        _ controller: CameraKeyboardViewController,
        didSelectVideo videoURL: URL,
        duration: TimeInterval
    ) {
        // Video can be longer than allowed to be uploaded. Then we need to add user the possibility to trim it.
        if duration > userSession.maxVideoLength {
            let videoEditor = StatusBarVideoEditorController()
            videoEditor.delegate = self
            videoEditor.videoMaximumDuration = userSession.maxVideoLength
            videoEditor.videoPath = videoURL.path
            videoEditor.videoQuality = .typeMedium

            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                hideCameraKeyboardViewController {
                    videoEditor.modalPresentationStyle = .popover

                    self.present(videoEditor, animated: true)

                    let popover = videoEditor.popoverPresentationController
                    popover?.sourceView = self.parent?.view

                    // Arrow point to camera button.
                    popover?.permittedArrowDirections = .down

                    popover?.sourceRect = self.photoButton.popoverSourceRect(from: self)

                    if let parentView = self.parent?.view {
                        videoEditor.preferredContentSize = parentView.frame.size
                    }
                }
            default:
                present(videoEditor, animated: true) {}
            }
        } else {
            let context = ConfirmAssetViewController.Context(
                asset: .video(url: videoURL),
                onConfirm: { [unowned self] _ in
                    dismiss(animated: true)
                    uploadFiles(at: [videoURL])
                },
                onCancel: { [unowned self] in
                    dismiss(animated: true) {
                        self.mode = .camera
                        self.inputBar.textView.becomeFirstResponder()
                    }
                }
            )
            let confirmVideoViewController = ConfirmAssetViewController(context: context)
            confirmVideoViewController.previewTitle = conversation.displayNameWithFallback

            view.window?.endEditing(true)
            present(confirmVideoViewController, animated: true)
        }
    }

    func cameraKeyboardViewController(
        _ controller: CameraKeyboardViewController,
        didSelectImage image: SendableImage,
        isFromCamera: Bool
    ) {
        showConfirmationForImage(
            image,
            isFromCamera: isFromCamera
        )
    }

    @objc
    func image(_ image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error {
            WireLogger.ui.error("didFinishSavingWithError: \(error)")
        }
    }

    // MARK: - Video save callback

    @objc
    func video(_ image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error {
            WireLogger.ui.error("Error saving video: \(error)")
        }
    }

    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        hideCameraKeyboardViewController { [self] in
            shouldRefocusKeyboardAfterImagePickerDismiss = true
            presentImagePicker(
                sourceType: .camera,
                mediaTypes: [UTType.movie.identifier, UTType.image.identifier],
                allowsEditing: false,
                pointToView: photoButton.imageView!
            )
        }
    }

    func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        hideCameraKeyboardViewController { [self] in
            shouldRefocusKeyboardAfterImagePickerDismiss = true
            presentImagePicker(
                sourceType: .photoLibrary,
                mediaTypes: [UTType.movie.identifier, UTType.image.identifier],
                allowsEditing: false,
                pointToView: photoButton.imageView!
            )
        }
    }

    func showConfirmationForImage(
        _ image: SendableImage,
        isFromCamera: Bool
    ) {
        let mediaAsset: MediaAsset = if
            image.utType == .gif,
            let gifImage = FLAnimatedImage(animatedGIFData: image.data),
            gifImage.frameCount > 1 {
            gifImage
        } else {
            UIImage(data: image.data) ?? UIImage()
        }

        let context = ConfirmAssetViewController.Context(
            asset: .image(mediaAsset: mediaAsset),
            onConfirm: { [weak self] (editedImage: UIImage?) in
                guard let self else { return }
                dismiss(animated: true) {
                    self.writeToSavedPhotoAlbumIfNecessary(
                        imageData: image.data,
                        isFromCamera: isFromCamera
                    )

                    let dataToSend = editedImage?.pngData() ?? image.data
                    let utType: UTType = if editedImage != nil {
                        .png
                    } else {
                        image.utType ?? .image
                    }

                    if self.userSession.isWireDriveEnabled,
                       self.conversation.isWireDriveEnabled {
                        self.uploadDraft(data: dataToSend, type: utType)
                    } else {
                        let image = SendableImage(
                            name: nil,
                            utType: utType,
                            data: dataToSend
                        )
                        self.sendController.sendMessage(
                            image: image,
                            userSession: self.userSession
                        )
                    }
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.mode = .camera
                    self?.inputBar.textView
                        .becomeFirstResponder()
                }
            }
        )

        let confirmImageViewController = ConfirmAssetViewController(context: context)
        confirmImageViewController.previewTitle = conversation.displayNameWithFallback

        view.window?.endEditing(true)
        present(confirmImageViewController, animated: true)
    }

    private func executeWithCameraRollPermission(_ closure: @escaping (_ success: Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    closure(true)
                default:
                    closure(false)
                }
            }
        }
    }

    private func writeToSavedPhotoAlbumIfNecessary(imageData: Data, isFromCamera: Bool) {
        guard isFromCamera,
              mediaShareRestrictionManager.hasAccessToCameraRoll,
              SecurityFlags.cameraRoll.isEnabled,
              let image = UIImage(data: imageData as Data)
        else {
            return
        }
        let selector = #selector(ConversationInputBarViewController.image(_:didFinishSavingWithError:contextInfo:))
        UIImageWriteToSavedPhotosAlbum(image, self, selector, nil)
    }

    func convertVideoAtPath(
        _ inputPath: String,
        completion: @escaping (_ success: Bool, _ resultPath: String?, _ duration: TimeInterval) -> Void
    ) {

        let lastPathComponent = (inputPath as NSString).lastPathComponent

        let filename: String = ((lastPathComponent as NSString).deletingPathExtension as NSString)
            .appendingPathExtension("mp4") ?? "video.mp4"

        let videoURLAsset = AVURLAsset(url: URL(fileURLWithPath: inputPath))

        videoURLAsset
            .convert(
                filename: filename,
                fileLengthLimit: Int64(userSession.maxUploadFileSize)
            ) { URL, videoAsset, error in
                guard let resultURL = URL, error == nil else {
                    completion(false, .none, 0)
                    return
                }
                completion(true, resultURL.path, CMTimeGetSeconds((videoAsset?.duration)!))
            }
    }
}

extension ConversationInputBarViewController: UIVideoEditorControllerDelegate {

    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismiss(animated: true, completion: .none)
    }

    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismiss(animated: true, completion: .none)

        let activityIndicator = BlockingActivityIndicator(view: editor.view)
        activityIndicator.start()

        convertVideoAtPath(editedVideoPath) { success, resultPath, _ in
            activityIndicator.stop()

            guard let path = resultPath, success else {
                return
            }

            self.uploadFiles(at: [URL(fileURLWithPath: path)])
        }
    }

    func videoEditorController(
        _ editor: UIVideoEditorController,
        didFailWithError error: Error
    ) {
        editor.dismiss(animated: true, completion: .none)
        WireLogger.ui.error("Video editor failed with error: \(error)")
    }
}

extension ConversationInputBarViewController: CanvasViewControllerDelegate {

    func canvasViewController(
        _ canvasViewController: CanvasViewController,
        didExportImage image: UIImage
    ) {
        hideCameraKeyboardViewController { [weak self] in
            guard let self else { return }

            dismiss(animated: true) {
                if let imageData = image.pngData() {
                    if self.userSession.isWireDriveEnabled,
                       self.conversation.isWireDriveEnabled {
                        self.uploadDraft(data: imageData, type: .png)
                    } else {
                        let image = SendableImage(
                            name: nil,
                            utType: .png,
                            data: imageData
                        )
                        self.sendController.sendMessage(
                            image: image,
                            userSession: self.userSession
                        )
                    }
                }
            }
        }
    }

    private func uploadDraft(data: Data, type: UTType) {
        Task.detached { [uploadDraftUseCase] in
            // We don't care about the result of the operation here as we will be observing changes.
            do {
                try await uploadDraftUseCase.invoke(data: data, type: type)
            } catch {
                WireLogger.conversation.error("Failed to upload file: \(error)")
            }
        }
    }
}

// MARK: - CameraViewController

extension ConversationInputBarViewController {

    func showCameraAndPhotos() {
        UIApplication.wr_requestVideoAccess { [mediaShareRestrictionManager] _ in
            if SecurityFlags.cameraRoll.isEnabled,
               mediaShareRestrictionManager.hasAccessToCameraRoll {
                self.executeWithCameraRollPermission { _ in
                    self.mode = .camera
                    self.inputBar.textView.becomeFirstResponder()
                }
            } else {
                self.mode = .camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
    }

    @objc
    func cameraButtonPressed(_ sender: Any?) {
        if let svc = ZClientViewController.shared?.mainSplitViewController, !svc.isCollapsed {
            svc.hideSidebar()
        }

        if mode == .camera {
            inputBar.textView.resignFirstResponder()
            cameraKeyboardViewController = nil
            delay(0.3) {
                self.mode = .textInput
            }
        } else {
            let checker = PrivacyWarningChecker(conversation: conversation, continueAction: { [self] in
                showCameraAndPhotos()
            })
            checker.performAction()
        }
    }
}
