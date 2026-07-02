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

import PhotosUI
import WireLogging

// MARK: - PHPicker delegate methods used only for Wire drive conversation (allowing multiple media selection).

extension ConversationInputBarViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        showCamera()

        let draftsLocalIdentifiers = attachmentsCarouselViewModel.draftsLocalIdentifiers
        let selectedIdentifiers = results.compactMap(\.assetIdentifier)
        let deselectedDraftIdentifiers = draftsLocalIdentifiers.filter { !selectedIdentifiers.contains($0) }

        for deselectedDraftIdentifier in deselectedDraftIdentifiers {
            removeDraft(localIdentifier: deselectedDraftIdentifier)
        }

        for result in results {
            let localIdentifier = result.assetIdentifier
            let provider = result.itemProvider
            let isImage = provider.canLoadObject(ofClass: UIImage.self)
            let isVideo = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)

            // filters out already previously selected assets.
            if let localIdentifier, attachmentsCarouselViewModel.draftsLocalIdentifiers.contains(localIdentifier) {
                continue
            }

            if isImage {
                processWireDriveImage(provider: provider, localIdentifier: localIdentifier)
            } else if isVideo {
                processWireDriveVideo(provider: provider, localIdentifier: localIdentifier)
            }
        }
    }

    private func processWireDriveImage(provider: NSItemProvider, localIdentifier: String?) {
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            guard let image = image as? UIImage, let data = image.jpegData(compressionQuality: 0.9) else { return }

            DispatchQueue.main.async {
                let checker = PrivacyWarningChecker(conversation: self.conversation) {
                    self.uploadDraft(
                        data: data,
                        type: .jpeg,
                        localIdentifier: localIdentifier
                    )
                }

                checker.performAction()
            }
        }
    }

    private func processWireDriveVideo(provider: NSItemProvider, localIdentifier: String?) {
        let filename = String.filename(for: userSession.selfUser)
        let fileLengthLimit = Int64(userSession.maxUploadFileSize)

        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
            guard let url, error == nil else {
                return WireLogger.wireDrive.error("Could not load video: \(String(describing: error))")
            }

            let videoTempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(filename)
                .appendingPathExtension(url.pathExtension)

            do {
                try FileManager.default.removeTmpIfNeededAndCopy(fileURL: url, tmpURL: videoTempURL)
            } catch {
                return WireLogger.wireDrive.error("Cannot copy video from \(url) to \(videoTempURL): \(error)")
            }

            AVURLAsset.convertVideoToUploadFormat(at: videoTempURL, fileLengthLimit: fileLengthLimit) { url, _, error in
                guard error == nil, let url else { return }
                self.uploadVideoFile(.init(url: url, localIdentifier: localIdentifier))
            }

        }

    }
}
