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
import Social
import UIKit
import UniformTypeIdentifiers
import WireDesign

/// The description of the preview that can be displayed for an attachment.

enum PreviewItem {
    case image(UIImage)
    case remoteURL(URL)
    case placeholder(StyleKitIcon)
}

extension SLComposeServiceViewController {
    /// Fetches the preview item of the main attachment in the background and provided the result to the UI
    /// for displaying it to the user.
    ///
    /// - parameter completionHandler: The block of code that provided the result of the preview lookup.
    /// - parameter item: The preview item for the attachment, if it could be determined.
    /// - parameter displayMode: The special mode in which the preview should displayed, if any.

    func fetchMainAttachmentPreview(_ completionHandler: @escaping (
        _ item: PreviewItem?,
        _ displayMode: PreviewDisplayMode?
    ) -> Void) {
        func completeTask(_ result: PreviewItem?, _ preferredDisplayMode: PreviewDisplayMode?) {
            DispatchQueue.main.async { completionHandler(result, preferredDisplayMode) }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let attachments = self.appendLinkFromTextIfNeeded(),
                  let (attachmentType, attachment) = attachments.main else {
                completeTask(nil, nil)
                return
            }

            let numberOfAttachments = attachments.values.reduce(0) { $0 + $1.count }
            let defaultDisplayMode: PreviewDisplayMode? = numberOfAttachments > 1 ? .mixed(numberOfAttachments, nil) :
                nil

            switch attachmentType {
            case .walletPass, .image:
                self.loadSystemPreviewForAttachment(attachment, type: attachmentType) { image, preferredDisplayMode in
                    completeTask(image, .combined(defaultDisplayMode, preferredDisplayMode))
                }

            case .video:
                self.loadSystemPreviewForAttachment(attachment, type: attachmentType) { image, preferredDisplayMode in
                    completeTask(image, .combined(defaultDisplayMode, preferredDisplayMode) ?? .video)
                }

            case .rawFile,
                 .fileUrl:
                let fallbackIcon = self.fallbackIcon(forAttachment: attachment, ofType: .rawFile)
                completeTask(.placeholder(fallbackIcon), .combined(defaultDisplayMode, .placeholder))

            case .url:
                let displayMode = PreviewDisplayMode.combined(defaultDisplayMode, .placeholder)

                attachment.fetchURL {
                    if let url = $0 {
                        guard !url.isFileURL else {
                            completeTask(.placeholder(.document), displayMode)
                            return
                        }
                        completeTask(.remoteURL(url), displayMode)
                    } else {
                        completeTask(.placeholder(.paperclip), displayMode)
                    }
                }
            }
        }
    }

    func appendLinkFromTextIfNeeded() -> [AttachmentType: [NSItemProvider]]? {
        guard let text = contentText,
              var attachments = extensionContext?.attachments else {
            return nil
        }

        let matches = text.URLsInString

        if let match = matches.first,
           let item = NSItemProvider(contentsOf: match),
           attachments.filter(\.hasURL).isEmpty {
            attachments.append(item)
        }

        return attachments.sorted
    }

    /// Loads the system preview for the item, if possible.
    ///
    /// This method generally works for movies, photos, wallet passes. It does not generate any preview for items shared
    /// from the iCloud drive app.

    private func loadSystemPreviewForAttachment(
        _ item: NSItemProvider,
        type: AttachmentType,
        completionHandler: @escaping (PreviewItem, PreviewDisplayMode?) -> Void
    ) {
        item
            .loadPreviewImage(options: [
                NSItemProviderPreferredImageSizeKey: PreviewDisplayMode
                    .pixelSize,
            ]) { container, error in
                func useFallbackIcon() {
                    let fallbackIcon = self.fallbackIcon(forAttachment: item, ofType: type)
                    completionHandler(.placeholder(fallbackIcon), .placeholder)
                }

                guard error == nil else {
                    useFallbackIcon()
                    return
                }

                if let image = container as? UIImage {
                    completionHandler(PreviewItem.image(image), nil)
                } else if let data = container as? Data {
                    guard let image = UIImage(data: data) else {
                        useFallbackIcon()
                        return
                    }
                    completionHandler(PreviewItem.image(image), nil)
                } else {
                    useFallbackIcon()
                }
            }
    }

    /// Returns the placeholder icon for the attachment of the specified type.
    private func fallbackIcon(forAttachment item: NSItemProvider, ofType type: AttachmentType) -> StyleKitIcon {
        switch type {
        case .video:
            .movie

        case .image:
            .photo

        case .walletPass,
             .fileUrl:
            .document

        case .rawFile:
            if item.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                .microphone
            } else {
                .document
            }

        case .url:
            .paperclip
        }
    }
}

// MARK: - PreviewDisplayMode.combined

extension PreviewDisplayMode {
    /// Combines the current display mode with the current one if they're compatible.
    fileprivate static func combined(
        _ defaultDisplayMode: PreviewDisplayMode?,
        _ preferredDisplayMode: PreviewDisplayMode?
    ) -> Self? {
        guard let defaultDisplayMode else { return preferredDisplayMode }
        guard case let .mixed(count, _) = defaultDisplayMode else { return defaultDisplayMode }
        return .mixed(count, preferredDisplayMode)
    }
}

// MARK: - Attachment Main

extension [AttachmentType: [NSItemProvider]] {
    /// Determines the main preview item for the post.
    ///
    /// We determine this using the following rules:
    /// - media = video AND/OR photo
    /// - passes OR media OR file
    /// - passes OR media OR file > URL
    /// - video > photo

    fileprivate var main: (AttachmentType, NSItemProvider)? {
        let sortedAttachments = self

        for attachmentType in AttachmentType.allCases {
            if let item = sortedAttachments[attachmentType]?.first {
                return (attachmentType, item)
            }
        }

        return nil
    }
}
