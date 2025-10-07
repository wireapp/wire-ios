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

package import Foundation
import UniformTypeIdentifiers
import WireLogging
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

    /// Whether the item is deleted or in the recycle bin.
    let isDeleted: Bool

}

@MainActor
package final class WireCellsAttachmentsPreviewViewModel: ObservableObject {

    private let attachments: [WireCellsMessageAttachment]
    private let fetchNodesUseCase: WireCellsFetchNodesUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let lastOpenRequest: WireCellsLastOpenRequest

    @Published var items: [WireCellsAttachmentsPreviewViewItem]

    package init(
        attachments: [WireCellsMessageAttachment],
        fetchNodesUseCase: WireCellsFetchNodesUseCase,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest
    ) {
        self.attachments = attachments
        self.fetchNodesUseCase = fetchNodesUseCase
        self.getAssetUseCase = getAssetUseCase
        self.localAssetRepository = localAssetRepository
        self.lastOpenRequest = lastOpenRequest

        self.items = attachments.map { WireCellsAttachmentsPreviewViewItem($0, isDeleted: false) }
    }

    /// Returns a `WireCellsAttachmentsPreviewView` for the item at the given index.
    func itemViewModel(index: Int) -> WireCellsAttachmentsPreviewItemViewModel {
        WireCellsAttachmentsPreviewItemViewModel(
            item: items[index],
            getAssetUseCase: getAssetUseCase,
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest
        )
    }

    /// Fetches the latest nodes from the backend and updates the view model's items if necessary.
    func fetchLatest() async {
        do {
            let (nodes, _) = try await fetchNodesUseCase.invoke(searchTerm: nil, offset: 0)

            items = attachments.map { attachment in
                if let node = nodes.first(where: { $0.id == attachment.nodeID }) {
                    WireCellsAttachmentsPreviewViewItem(node)
                } else {
                    WireCellsAttachmentsPreviewViewItem(attachment, isDeleted: true)
                }
            }
        } catch {
            WireLogger.wireCells.info("Failed to fetch latest nodes: \(error)")
        }
    }
}

private extension WireCellsAttachmentsPreviewViewItem {

    init(_ value: WireCellsMessageAttachment, isDeleted: Bool) {
        let url = value.initialName.flatMap { URL(string: $0) }
        let fileType = value.contentType.flatMap { UTType(mimeType: $0) }
        let fileExtension = url?.pathExtension

        self.nodeID = value.nodeID
        self.fileIcon = .make(type: fileType, fileExtension: fileExtension)
        self.fileName = url?.deletingPathExtension().lastPathComponent
        self.fileExtension = fileExtension
        self.fileSize = value.initialSize
        self.isDeleted = isDeleted
    }

    init(_ value: WireCellsNode) {
        let url = URL(string: value.path)
        let fileType = value.mimeType.flatMap { UTType(mimeType: $0) }
        let fileExtension = url?.pathExtension

        self.nodeID = value.id
        self.fileIcon = .make(type: fileType, fileExtension: value.path)
        self.fileName = url?.deletingPathExtension().lastPathComponent
        self.fileExtension = fileExtension
        self.fileSize = value.size.map { Int($0) }
        self.isDeleted = value.isRecycled
    }

}
