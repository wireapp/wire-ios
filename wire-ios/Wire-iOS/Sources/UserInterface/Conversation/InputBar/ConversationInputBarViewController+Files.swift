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

extension ConversationInputBarViewController {

    @discardableResult
    private func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            WireLogger.ui.error("Cannot delete folder at path \(path): \(error)")

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

        let files: [FileMetadata] = urls.map(FileMetadata.init)
        let charactersToReplace = uploadDraftUseCase.charactersToReplace

        if urls.contains(where: { $0.lastPathComponent.contains(where: { charactersToReplace.contains($0) }) }) {
            showAlertForFileNeedsRename(files)
        } else {
            continueUploadFiles(files)
        }
    }

    /// Metadata describing a selected file and its optional link to a Photos asset.
    struct FileMetadata {
        let url: URL

        /// Optional device Photos asset identifier used for draft handling in conversation previews
        /// (`PHAsset.localIdentifier` / `PHPickerResult.assetIdentifier`).
        let localIdentifier: String?

        init(url: URL, localIdentifier: String?) {
            self.url = url
            self.localIdentifier = localIdentifier
        }

        init(url: URL) {
            self.url = url
            self.localIdentifier = nil
        }
    }

    func uploadVideoFile(_ file: FileMetadata) {
        let charactersToReplace = uploadDraftUseCase.charactersToReplace

        if file.url.lastPathComponent.contains(where: { charactersToReplace.contains($0) }) {
            showAlertForFileNeedsRename([file])
        } else {
            continueUploadFiles([file])
        }
    }

    private func continueUploadFiles(_ files: [FileMetadata]) {
        if useWireDrive() {
            for file in files {
                Task.detached { [uploadDraftUseCase] in
                    // We don't care about the result of the operation here as we will be observing changes.
                    do {
                        try await uploadDraftUseCase.invoke(fileURL: file.url, localIdentifier: file.localIdentifier)
                    } catch {
                        WireLogger.conversation.error("Failed to upload file: \(error)")
                    }
                }
            }
        } else if files.count == 1 {
            uploadFile(at: files[0].url)
        } else {
            do {
                let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
                let archiveURL = temporaryDirectory.appending(path: "archive.zip", directoryHint: .notDirectory)
                try ZIPFoundationFileArchiver().zipResources(at: files.map(\.url), into: archiveURL)
                uploadFile(at: archiveURL)
            } catch {
                WireLogger.ui.error("Cannot archive files at URLs: \(files.map(\.url))")
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
            WireLogger.ui.error("Cannot get file size on selected file:")
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
                    WireLogger.messageProcessing.warn("Failed to append file. Reason: \(error.localizedDescription)")
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

    private func showAlertForFileNeedsRename(_ files: [FileMetadata]) {
        let characters = uploadDraftUseCase.charactersToReplace.map(String.init)
        let formattedCharacters = characters.dropLast().joined(separator: " ")
        let lastCharacter = characters.last ?? ""

        let alert = UIAlertController(
            title: L10n.Localizable.Content.UploadedFileNeedsRename.title,
            message: L10n.Localizable.Content.UploadedFileNeedsRename.message(formattedCharacters, lastCharacter),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Localizable.Content.UploadedFileNeedsRename.cancelButton,
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Localizable.Content.UploadedFileNeedsRename.confirmButton,
                style: .default,
                handler: { [weak self] _ in
                    self?.continueUploadFiles(files)
                }
            )
        )

        present(alert, animated: true)
    }
}
