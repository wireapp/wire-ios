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

import Foundation
import WireCommonComponents
import WireLogging
import WireMessagingAssembly
import WireSyncEngine
import WireUtilitiesPackage

extension ConversationInputBarViewController: UINavigationControllerDelegate {}

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController+Files")

extension ConversationInputBarViewController {

    @discardableResult
    private func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            zmLog.error("Cannot delete folder at path \(path): \(error)")

            return false
        }

        return true
    }

    /// Upload files at the given `urls`.
    ///
    /// - parameter urls: The URLs of the files to upload.
    /// - note: If wire drive is enabled, each file will be uploaded separately. If wire drive is disabled and there are
    /// multiple files, these will be zipped and then uploaded.

    func uploadFiles(at urls: [URL]) {
        guard !urls.isEmpty else { return }

        if userSession.isWireDriveEnabled, conversation.isWireDriveEnabled {
            for url in urls {
                Task.detached { [uploadDraftUseCase] in
                    // We don't care about the result of the operation here as we will be observing changes.
                    do {
                        try await uploadDraftUseCase.invoke(fileURL: url)
                    } catch {
                        WireLogger.conversation.error("Failed to upload file: \(error)")
                    }
                }
            }
        } else if urls.count == 1 {
            uploadFile(at: urls[0])
        } else {
            do {
                let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
                let archiveURL = temporaryDirectory.appending(path: "archive.zip", directoryHint: .notDirectory)
                try ZIPFoundationFileArchiver().zipResources(at: urls, into: archiveURL)
                uploadFile(at: archiveURL)
            } catch {
                zmLog.error("Cannot archive files at URLs: \(urls)")
            }
        }
    }

    /// upload a single file
    ///
    /// - Parameter url: the URL of the file
    private func uploadFile(at url: URL) {
        guard let conversation = conversation as? ZMConversation else { return }

        let completion: Completion = { [weak self] in
            self?.removeItem(atPath: url.path)
        }

        guard let fileSize: UInt64 = url.fileSize else {
            zmLog.error("Cannot get file size on selected file:")
            parent?.dismiss(animated: true)
            return completion()
        }

        guard fileSize <= userSession.maxUploadFileSize else {
            // file exceeds maximum allowed upload size
            parent?.dismiss(animated: false)
            showAlertForFileTooBig()
            return completion()
        }

        Task { @MainActor in
            let metadata = await fileMetaDataGenerator.metadataForFile(at: url)

            impactFeedbackGenerator.prepare()

            userSession.perform { [weak self] in

                guard let self else { return }

                impactFeedbackGenerator.impactOccurred()

                do {
                    let useCase = userSession.makeAppendFileMessageUseCase()
                    try useCase.invoke(with: metadata, in: conversation)
                } catch {
                    Logging.messageProcessing.warn("Failed to append file. Reason: \(error.localizedDescription)")
                }

                completion()
            }
        }

        parent?.dismiss(animated: true)
    }

    func execute(videoPermissions toExecute: @escaping () -> Void) {
        UIApplication.wr_requestOrWarnAboutVideoAccess { granted in
            if granted {
                UIApplication.wr_requestOrWarnAboutMicrophoneAccess { granted in
                    if granted {
                        toExecute()
                    }
                }
            }
        }
    }

    private func showAlertForFileTooBig() {
        let maxSizeString = ByteCountFormatter.string(
            fromByteCount: Int64(userSession.maxUploadFileSize),
            countStyle: .binary
        )
        let errorMessage = L10n.Localizable.Content.File.tooBig(maxSizeString)

        let alert = UIAlertController(
            title: nil,
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(alert, animated: true)
    }
}
