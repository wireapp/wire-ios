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
package import WireMessagingDomain
import WireMessagingDomainSupport

@MainActor
package final class WireCellsAttachmentsPreviewViewModel: ObservableObject {

    private let fetchNodeUseCase: WireCellsFetchNodeUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier

    let attachments: [WireCellsMessageAttachment]
    let alignment: HorizontalAlignment

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
    }

    /// Returns a `WireCellsAttachmentsPreviewView` for the item at the given index.
    func itemViewModel(index: Int) -> WireCellsAttachmentsPreviewItemViewModel {
        WireCellsAttachmentsPreviewItemViewModel(
            attachment: attachments[index],
            alignment: alignment,
            fetchNodeUseCase: fetchNodeUseCase,
            getAssetUseCase: getAssetUseCase,
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest,
            nodeRenameNotifier: nodeRenameNotifier,
            displayStyle: attachments.count > 1 ? .small : .large
        )
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
