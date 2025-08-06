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
@preconcurrency import QuickLookThumbnailing
import UniformTypeIdentifiers
import WireLogging

@MainActor
public final class AttachmentsCarouselViewModel: ObservableObject {

    private enum Constants {
        static let thumbnailSize = CGSize(width: 74, height: 74)
    }

    private var drafts: [WireCellsDraft] = []
    private var thumbnails: [UUID: UIImage] = [:]
    private var generatingThumbnailIDs: Set<UUID> = []

    @Published private(set) var items: [AttachmentsCarouselItem]

    public convenience init() {
        self.init(items: [])
    }

    init(items: [AttachmentsCarouselItem]) {
        self.items = items
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
            !generatingThumbnailIDs.contains(draft.nodeID),
            thumbnails[draft.versionID] == nil,
            let fileType = draft.fileType,
            fileType.conforms(to: .image) || fileType.conforms(to: .audiovisualContent)
        else { return }

        let request = QLThumbnailGenerator.Request(
            fileAt: draft.assetURL,
            size: Constants.thumbnailSize,
            scale: UIScreen.main.scale,
            representationTypes: .thumbnail
        )

        do {
            let result = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            thumbnails[draft.versionID] = result.uiImage
            refreshItems()
        } catch {
            WireLogger.wireCells.error("Failed to generate thumbnail for file type: \(fileType.identifier)")
        }

        generatingThumbnailIDs.remove(draft.nodeID)
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
        guard let value else {
            self = .document
            return
        }

        if value.conforms(to: .image) {
            self = .image(thumbnail: thumbnail)
        } else if value.conforms(to: .audiovisualContent) {
            self = .video(thumbnail: thumbnail)
        } else if value.conforms(to: .audio) {
            self = .audio(samples: []) // FIXME: [WPB-19268] Set audio sample data
        } else {
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
