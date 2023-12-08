//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import MobileCoreServices
import Photos
import FLAnimatedImage
import WireSyncEngine
import WireCommonComponents

class InputBarCameraHandler: NSObject,
                             CameraKeyboardViewControllerDelegate,
                             UINavigationControllerDelegate,
                             UIVideoEditorControllerDelegate {

    weak var viewController: ConversationInputBarViewController?
    var splitLayoutObservable: SplitLayoutObservable
    let userSession: UserSession

    init(
        viewController: ConversationInputBarViewController,
        splitLayoutObservable: SplitLayoutObservable,
        userSession: UserSession
    ) {
        self.viewController = viewController
        self.splitLayoutObservable = splitLayoutObservable
        self.userSession = userSession
    }

    func activate() {
        setupCameraInterface()
    }

    private func setupCameraInterface() {
        // Now using the correct splitLayoutObservable
        let cameraKeyboardViewController = CameraKeyboardViewController(splitLayoutObservable: splitLayoutObservable)
        cameraKeyboardViewController.delegate = self
        viewController?.cameraKeyboardViewController = cameraKeyboardViewController
        // More setup if needed...
    }

    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo videoURL: URL, duration: TimeInterval) {
        guard let viewController = viewController else { return }
        let userSession = viewController.userSession

        // Video can be longer than allowed to be uploaded. Then we need to add the user the possibility to trim it.
        if duration > userSession.maxVideoLength {
            let videoEditor = StatusBarVideoEditorController()
            videoEditor.delegate = self
            videoEditor.videoMaximumDuration = userSession.maxVideoLength
            videoEditor.videoPath = videoURL.path
            videoEditor.videoQuality = .typeMedium

            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                viewController.hideCameraKeyboardViewController {
                    videoEditor.modalPresentationStyle = .popover

                    viewController.present(videoEditor, animated: true)

                    let popover = videoEditor.popoverPresentationController
                    popover?.sourceView = viewController.parent?.view

                    // Arrow point to camera button.
                    popover?.permittedArrowDirections = .down

                    // Ensure the popoverSourceRect is safely unwrapped
                    let popoverSourceRect = viewController.photoButton.popoverSourceRect(from: viewController)
                    popover?.sourceRect = popoverSourceRect

                    // Set the preferredContentSize if the parent view can be unwrapped
                    if let parentView = viewController.parent?.view {
                        videoEditor.preferredContentSize = parentView.frame.size
                    }
                }
            default:
                viewController.present(videoEditor, animated: true)
            }
        } else {
            let context = ConfirmAssetViewController.Context(asset: .video(url: videoURL),
                                                             onConfirm: { [weak self] _ in
                                                                viewController.dismiss(animated: true)
                                                                viewController.uploadFile(at: videoURL)
                                                             },
                                                             onCancel: { [weak self] in
                                                                viewController.dismiss(animated: true) {
                                                                    self?.viewController?.mode = .camera
                                                                    self?.viewController?.inputBar.textView.becomeFirstResponder()
                                                                }
                                                             })
            let confirmVideoViewController = ConfirmAssetViewController(context: context)
            confirmVideoViewController.previewTitle = viewController.conversation.displayNameWithFallback.localized

            viewController.endEditing()
            viewController.present(confirmVideoViewController, animated: true)
        }
    }

    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData imageData: Data, isFromCamera: Bool, uti: String?) {
        showConfirmationForImage(imageData, isFromCamera: isFromCamera, uti: uti)
    }

    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        // Logic for opening full-screen camera
        // Adapt this method
        // ...
    }

    func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        // Logic for opening camera roll
        // Adapt this method
        // ...
    }

    func showConfirmationForImage(_ imageData: Data,
                                  isFromCamera: Bool,
                                  uti: String?) {
        let mediaAsset: MediaAsset
        guard let viewController = viewController else { return }

        if uti == UTType.gif.identifier,
           let gifImage = FLAnimatedImage(animatedGIFData: imageData),
           gifImage.frameCount > 1 {
            mediaAsset = gifImage
        } else {
            mediaAsset = UIImage(data: imageData) ?? UIImage()
        }

        let context = ConfirmAssetViewController.Context(asset: .image(mediaAsset: mediaAsset),
                                                         onConfirm: { (editedImage: UIImage?) in
                                                                    viewController.dismiss(animated: true) {
                                                                        viewController.writeToSavedPhotoAlbumIfNecessary(imageData: imageData,
                                                                                                      isFromCamera: isFromCamera)
                                                                        viewController.sendController.sendMessage(withImageData: editedImage?.pngData() ?? imageData, userSession: self.userSession)
                                                                }
                                                            },
                                                         onCancel: {
                                                                            viewController.dismiss(animated: true) {
                                                                            viewController.mode = .camera
                                                                            viewController.inputBar.textView.becomeFirstResponder()
                                                                        }
                                                                    })

    }
}
