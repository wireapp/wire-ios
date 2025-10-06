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
import UniformTypeIdentifiers
package import WireMessagingDomain



/// An item in the `WireCellsAttachmentsPreviewView`.
struct WireCellsAttachmentsPreviewViewItem: Identifiable, Hashable {

    var id: UUID { nodeID }

    /// Identifier of this item on the wire cells backend.
    let nodeID: UUID

    /// Icon representing the file type of this attachment.
    let fileIcon: FileIcon

    /// The name of the file, if available.
    let fileName: String?

    let fileExtension: String?

    /// The size in bytes of the attachment.
    let fileSize: Int?

}

@MainActor
package final class WireCellsAttachmentsPreviewViewModel: ObservableObject {

    private let attachments: [WireCellsMessageAttachment]

    @Published var items: [WireCellsAttachmentsPreviewViewItem]

    package init(attachments: [WireCellsMessageAttachment]) {
        self.attachments = attachments
        self.items = attachments.map { WireCellsAttachmentsPreviewViewItem($0) }
    }

    /// Returns a `WireCellsAttachmentsPreviewView` for the item at the given index.
    func itemViewModel(index: Int) -> WireCellsAttachmentsPreviewItemViewModel {
        WireCellsAttachmentsPreviewItemViewModel(item: items[index])
    }
}

private extension WireCellsAttachmentsPreviewViewItem {

    init(_ value: WireCellsMessageAttachment) {
        let url = value.initialName.flatMap { URL(string: $0) }
        let fileType = value.contentType.flatMap { UTType(mimeType: $0) }
        let fileExtension = url?.pathExtension

        self.nodeID = value.nodeID
        self.fileIcon = .make(type: fileType, fileExtension: fileExtension)
        self.fileName = url?.deletingPathExtension().lastPathComponent
        self.fileExtension = fileExtension
        self.fileSize = value.initialSize
    }

}
