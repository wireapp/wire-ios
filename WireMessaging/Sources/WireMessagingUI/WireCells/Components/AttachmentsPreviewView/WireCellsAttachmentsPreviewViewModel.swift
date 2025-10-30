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

import Combine
import Foundation
package import SwiftUI
import UniformTypeIdentifiers
import WireLogging
package import WireMessagingDomain
import WireMessagingDomainSupport

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
    private let fetchNodeUseCase: WireCellsFetchNodeUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier

    let alignment: HorizontalAlignment
    @Published var items: [WireCellsAttachmentsPreviewViewItem]

    package init(
        attachments: [WireCellsMessageAttachment],
        alignment: HorizontalAlignment,
        fetchNodeUseCase: WireCellsFetchNodeUseCase,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest,
        nodeRenameNotifier: WireCellsNodeRenameNotifier
    ) {
        self.attachments = attachments
        self.alignment = alignment
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.localAssetRepository = localAssetRepository
        self.lastOpenRequest = lastOpenRequest
        self.nodeRenameNotifier = nodeRenameNotifier

        self.items = attachments.map { WireCellsAttachmentsPreviewViewItem($0, isDeleted: false) }
    }

    /// Returns a `WireCellsAttachmentsPreviewView` for the item at the given index.
    func itemViewModel(index: Int) -> WireCellsAttachmentsPreviewItemViewModel {
        WireCellsAttachmentsPreviewItemViewModel(
            item: items[index],
            alignment: alignment,
            fetchNodeUseCase: fetchNodeUseCase,
            getAssetUseCase: getAssetUseCase,
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest,
            nodeRenameNotifier: nodeRenameNotifier
        )
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

}

// MARK: - Previews

extension WireCellsAttachmentsPreviewViewModel {

    @MainActor
    static func makePreview() -> WireCellsAttachmentsPreviewViewModel {
        let attachments = [
            WireCellsMessageAttachment(
                nodeID: UUID(),
                contentType: "image/png",
                initialName: "Picture.png",
                initialSize: 1000,
                initialMetadata: nil
            ),
            WireCellsMessageAttachment(
                nodeID: UUID(),
                contentType: "video/mp4",
                initialName: "Video.mp4",
                initialSize: 2000,
                initialMetadata: nil
            ),
            WireCellsMessageAttachment(
                nodeID: UUID(),
                contentType: "application/pdf",
                initialName: "Document.pdf",
                initialSize: 3000,
                initialMetadata: nil
            )
        ]
        let nodesRepository = MockWireCellsNodesRepositoryProtocol()
        nodesRepository.getNodes_MockValue = (nodes: [], nextOffset: nil)
        nodesRepository.getNodeId_MockMethod = { _ in nil }

        let nodeCache = MockWireCellsNodeCacheProtocol()
        nodeCache.itemFor_MockMethod = { _ in nil }
        nodeCache.setItemFor_MockMethod = { _, _ in }

        let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = AnyPublisher(Just(nil))

        let fileCache = MockFileCache()
        fileCache.fileURLForKey_MockMethod = { _ in nil }

        return WireCellsAttachmentsPreviewViewModel(
            attachments: attachments,
            alignment: .leading,
            fetchNodeUseCase: WireCellsFetchNodeUseCase(
                repository: nodesRepository,
                cache: nodeCache
            ),
            getAssetUseCase: WireCellsGetAssetUseCase(
                localAssetRepository: localAssetRepository,
                fileCache: fileCache
            ),
            localAssetRepository: localAssetRepository,
            lastOpenRequest: WireCellsLastOpenRequest(),
            nodeRenameNotifier: WireCellsNodeRenameNotifier()
        )
    }

}
