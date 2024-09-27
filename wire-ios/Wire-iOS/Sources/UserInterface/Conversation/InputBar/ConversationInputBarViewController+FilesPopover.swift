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

import MobileCoreServices
import UniformTypeIdentifiers
import WireSyncEngine

// MARK: - ConversationInputBarViewController + UIDocumentPickerDelegate

extension ConversationInputBarViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        uploadFiles(at: urls)
    }
}

extension ConversationInputBarViewController {
    func createFileUploadActionSheet(sender: UIButton) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Alert actions  for debugging
        #if targetEnvironment(simulator)
            let plistHandler: ((UIAlertAction) -> Void) = { _ in
                self.userSession.enqueue {
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    guard let basePath = paths.first,
                          let sourceLocation = Bundle.main.url(forResource: "CountryCodes", withExtension: "plist")
                    else {
                        return
                    }

                    let destLocation = URL(fileURLWithPath: basePath)
                        .appendingPathComponent(sourceLocation.lastPathComponent)

                    try? FileManager.default.copyItem(at: sourceLocation, to: destLocation)
                    self.uploadFile(at: destLocation)
                }
            }

            alertController.addAction(UIAlertAction(
                title: "CountryCodes.plist",
                style: .default,
                handler: plistHandler
            ))

            let size = UInt(ZMUserSession.shared()?.maxUploadFileSize ?? 0) + 1
            let humanReadableSize = size / 1024 / 1024
            alertController.addAction(uploadTestAlertAction(
                size: size,
                title: "Big file (size = \(humanReadableSize) MB)",
                fileName: "BigFile.bin"
            ))

            alertController.addAction(uploadTestAlertAction(
                size: 20_971_520,
                title: "20 MB file",
                fileName: "20MBFile.bin"
            ))
            alertController.addAction(uploadTestAlertAction(
                size: 41_943_040,
                title: "40 MB file",
                fileName: "40MBFile.bin"
            ))

            if ZMUser.selfUser()?.hasTeam == true {
                alertController.addAction(uploadTestAlertAction(
                    size: 83_886_080,
                    title: "80 MB file",
                    fileName: "80MBFile.bin"
                ))
                alertController.addAction(uploadTestAlertAction(
                    size: 125_829_120,
                    title: "120 MB file",
                    fileName: "120MBFile.bin"
                ))
            }
        #endif

        let uploadVideoHandler: ((UIAlertAction) -> Void) = { [self] _ in
            presentImagePicker(
                sourceType: .photoLibrary,
                mediaTypes: [UTType.movie.identifier], allowsEditing: true,
                pointToView: videoButton.imageView!
            )
        }

        alertController.addAction(UIAlertAction(
            icon: .movie,
            title: L10n.Localizable.Content.File.uploadVideo,
            tintColor: view.tintColor,
            handler: uploadVideoHandler
        ))

        let takeVideoHandler: ((UIAlertAction) -> Void) = { _ in
            self.recordVideo()
        }

        alertController.addAction(UIAlertAction(
            icon: .cameraShutter,
            title: L10n.Localizable.Content.File.takeVideo,
            tintColor: view.tintColor,
            handler: takeVideoHandler
        ))

        let browseHandler: ((UIAlertAction) -> Void) = { _ in

            let documentPickerViewController = UIDocumentPickerViewController(
                forOpeningContentTypes: [UTType.item],
                asCopy: true
            )
            documentPickerViewController.delegate = self
            documentPickerViewController.allowsMultipleSelection = true
            self.present(documentPickerViewController, animated: true)
        }

        alertController.addAction(UIAlertAction(
            icon: .ellipsis,
            title: L10n.Localizable.Content.File.browse,
            tintColor: view.tintColor,
            handler: browseHandler
        ))

        alertController.addAction(.cancel())

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview!
            popoverPresentationController.sourceRect = sender.frame
        }

        return alertController
    }

    @objc
    func fileUploadPressed(_ sender: IconButton) {
        let checker = PrivacyWarningChecker(conversation: conversation) {
            self.showFileUploadActionSheet(sender)
        }

        checker.performAction()
    }

    private func showFileUploadActionSheet(_ sender: IconButton) {
        mode = ConversationInputBarViewControllerMode.textInput
        inputBar.textView.resignFirstResponder()

        let controller = createFileUploadActionSheet(sender: sender)

        present(controller, animated: true)
    }

    @objc
    func videoButtonPressed(_: IconButton) {
        let checker = PrivacyWarningChecker(conversation: conversation) {
            self.recordVideo()
        }
        checker.performAction()
    }

    private func recordVideo() {
        guard !CameraAccess.displayAlertIfOngoingCall(at: .recordVideo, from: self) else {
            return
        }

        presentImagePicker(
            sourceType: .camera,
            mediaTypes: [UTType.movie.identifier],
            allowsEditing: false,
            pointToView: videoButton.imageView!
        )
    }

    #if targetEnvironment(simulator)
        private func uploadTestAlertAction(size: UInt, title: String, fileName: String) -> UIAlertAction {
            UIAlertAction(title: title, style: .default, handler: { _ in
                self.userSession.enqueue {
                    let randomData = Data.secureRandomData(length: UInt(size))

                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = dir.appendingPathComponent(fileName)
                        try? randomData.write(to: fileURL)

                        self.uploadFile(at: fileURL)
                    }
                }
            })
        }
    #endif
}
