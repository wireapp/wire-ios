//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import UIKit
public import WireMessagingDomain
import QuickLookThumbnailing
import UniformTypeIdentifiers
import WireLegacyLogging

@MainActor
public final class AttachmentsCarouselViewModel: ObservableObject {

    private enum Constants {
        static let thumbnailSize = CGSize(width: 74, height: 74)
    }

    private let thumbnailGenerator: any ThumbnailGenerator

    private var drafts: [WireCellsDraft] = []
    private var thumbnails: [UUID: UIImage] = [:]
    private var generatingThumbnailIDs: Set<UUID> = []

    @Published private(set) var items: [AttachmentsCarouselItem]

    public convenience init() {
        self.init(items: [])
    }

    init(items: [AttachmentsCarouselItem], thumbnailGenerator: any ThumbnailGenerator = QLThumbnailGenerator.shared) {
        self.items = items
        self.thumbnailGenerator = thumbnailGenerator
    }

    public func update(with drafts: [WireCellsDraft]) {
        self.drafts = drafts
        refreshItems()

        for draft in drafts {
            Task { await generateThumbnail(for: draft) }
        }

        // In general there is no reason to keep thumbnails cached too long as the same thumbnail is unlikely to be
        // needed again once a message has been sent and re-generating thumbnails is cheap. When `drafts` is empty, its
        // a good time to remove them.
        if drafts.isEmpty {
            thumbnails.removeAll()
        }
    }

    private func refreshItems() {
        items = drafts.compactMap { AttachmentsCarouselItem(draft: $0, thumbnail: thumbnails[$0.versionID]) }
    }

    private func generateThumbnail(for draft: WireCellsDraft) async {
        guard
            !generatingThumbnailIDs.contains(draft.versionID),
            thumbnails[draft.versionID] == nil,
            let fileType = draft.fileType,
            fileType.conforms(to: .image) || fileType.conforms(to: .audiovisualContent), !fileType.conforms(to: .audio)
        else { return }

        generatingThumbnailIDs.insert(draft.versionID)

        do {
            let thumbnail = try await thumbnailGenerator.generateThumbnail(
                fileAt: draft.assetURL,
                size: Constants.thumbnailSize,
                scale: UIScreen.main.scale
            )
            thumbnails[draft.versionID] = thumbnail
            refreshItems()
        } catch {
            WireLogger.wireCells.error("Failed to generate thumbnail for file type: \(fileType.identifier)")
        }

        generatingThumbnailIDs.remove(draft.versionID)
    }

}

private extension AttachmentsCarouselItem {

    init?(draft: WireCellsDraft, thumbnail: UIImage?) {
        let state: AttachmentsCarouselItem.State
        switch draft.status {
        case let .uploading(progress):
            state = .uploading(progress: Double(progress))
        case .uploaded:
            state = .uploaded
        case .failed:
            state = .failed
        case .cancelled:
            return nil
        }

        let (name, fileExtension) = draft.nameAndExtension

        self.init(
            id: draft.nodeID,
            state: state,
            kind: AttachmentsCarouselItem.Kind(draft.fileType, thumbnail: thumbnail),
            name: name,
            fileExtension: fileExtension,
            size: draft.bytes.formatted(.byteCount(style: .decimal)),
            fileIcon: .make(type: draft.fileType, fileExtension: fileExtension)
        )
    }

    private static func nameAndExtension(from fileName: String) -> (name: String, extension: String?) {
        guard let url = URL(string: fileName) else {
            return (name: fileName, extension: nil)
        }

        return (name: url.deletingPathExtension().lastPathComponent, extension: url.pathExtension)
    }

}

private extension AttachmentsCarouselItem.Kind {

    init(_ value: UTType?, thumbnail: UIImage?) {
        let category = WireCellsFileCategory(value)

        switch category {
        case .image:
            self = .image(thumbnail: thumbnail)
        case .video:
            self = .video(thumbnail: thumbnail)
        case .audio:
            self = .audio(samples: []) // FIXME: [WPB-19268] Set audio sample data
        case .document:
            self = .document
        }
    }

}

private extension WireCellsDraft {

    var nameAndExtension: (name: String, extension: String) {
        let url = URL(fileURLWithPath: name)
        return (name: url.deletingPathExtension().lastPathComponent, extension: url.pathExtension)
    }

}
