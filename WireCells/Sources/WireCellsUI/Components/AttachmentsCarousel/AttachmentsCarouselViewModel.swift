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
public import WireCellsAPI
import UniformTypeIdentifiers

@MainActor
public final class AttachmentsCarouselViewModel: ObservableObject {

    @Published private(set) var items: [AttachmentsCarouselItem]

    public init(items: [AttachmentsCarouselItem]) {
        self.items = items
    }

    public func update(with drafts: [WireCellsDraft]) {
        items = drafts.compactMap { AttachmentsCarouselItem(draft: $0) }
    }

}

private extension AttachmentsCarouselItem {

    init?(draft: WireCellsDraft) {
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
            kind: AttachmentsCarouselItem.Kind(draft.fileType),
            name: name,
            fileExtension: fileExtension,
            size: draft.bytes.formatted(.byteCount(style: .decimal)),
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

    init(_ value: UTType?) {
        guard let value else {
            self = .document
            return
        }

        if value.conforms(to: .image) {
            self = .image(thumbnail: nil) // FIXME: [WPB-19266] Set image thumbnail data
        } else if value.conforms(to: .audiovisualContent) {
            self = .video(thumbnail: nil) // FIXME: [WPB-19267] Set video thumbnail data
        } else if value.conforms(to: .audio, ) {
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
