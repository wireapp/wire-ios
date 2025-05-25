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

        self.init(
            id: draft.id.uuid,
            state: state,
            kind: AttachmentsCarouselItem.Kind(draft.fileType),
            name: draft.name,
            size: draft.bytes.formatted(.byteCount(style: .memory))
        )
    }

}

private extension AttachmentsCarouselItem.Kind {

    init(_ value: UTType?) {
        guard let value else {
            self = .document(type: nil)
            return
        }

        // FIXME: [WPB-17604] Set preview data i.e. thumbnail or audio samples
        if value.conforms(to: .image) {
            self = .image(thumbnail: UIImage())
        } else if value.conforms(to: .audiovisualContent) {
            self = .video(thumbnail: UIImage())
        } else if value.conforms(to: .audio) {
            self = .audio(samples: [])
        } else {
            self = .document(type: value)
        }
    }

}
