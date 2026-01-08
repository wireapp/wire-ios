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

import Combine
import Foundation
package import SwiftUI
package import WireMessagingDomain
import WireMessagingDomainSupport

@MainActor
package final class WireDriveAttachmentsPreviewViewModel: ObservableObject {

    private let fetchNodeUseCase: WireDriveFetchNodeUseCase
    private let getAssetUseCase: WireDriveGetAssetUseCase
    private let nodeCache: any WireDriveNodeCacheProtocol
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let lastOpenRequest: WireDriveLastOpenRequest
    private let nodeRenameNotifier: WireDriveNodeRenameNotifier

    let attachments: [WireDriveMessageAttachment]
    let alignment: HorizontalAlignment

    package init(
        attachments: [WireDriveMessageAttachment],
        alignment: HorizontalAlignment,
        fetchNodeUseCase: WireDriveFetchNodeUseCase,
        getAssetUseCase: WireDriveGetAssetUseCase,
        nodeCache: any WireDriveNodeCacheProtocol,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        lastOpenRequest: WireDriveLastOpenRequest,
        nodeRenameNotifier: WireDriveNodeRenameNotifier
    ) {
        self.attachments = attachments
        self.alignment = alignment
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.nodeCache = nodeCache
        self.localAssetRepository = localAssetRepository
        self.lastOpenRequest = lastOpenRequest
        self.nodeRenameNotifier = nodeRenameNotifier
    }

    /// Returns a `WireDriveAttachmentsPreviewView` for the item at the given index.
    func itemViewModel(index: Int) -> WireDriveAttachmentsPreviewItemViewModel {
        WireDriveAttachmentsPreviewItemViewModel(
            attachment: attachments[index],
            alignment: alignment,
            fetchNodeUseCase: fetchNodeUseCase,
            getAssetUseCase: getAssetUseCase,
            nodeCache: nodeCache,
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest,
            nodeRenameNotifier: nodeRenameNotifier,
            displayStyle: attachments.count > 1 ? .small : .large
        )
    }

}

// MARK: - Previews

extension WireDriveAttachmentsPreviewViewModel {

    @MainActor
    static func makePreview() -> WireDriveAttachmentsPreviewViewModel {
        let attachments = [
            WireDriveMessageAttachment(
                nodeID: UUID(),
                contentType: "image/png",
                initialName: "Picture.png",
                initialSize: 1000,
                initialMetadata: nil
            ),
            WireDriveMessageAttachment(
                nodeID: UUID(),
                contentType: "video/mp4",
                initialName: "Video.mp4",
                initialSize: 2000,
                initialMetadata: nil
            ),
            WireDriveMessageAttachment(
                nodeID: UUID(),
                contentType: "application/pdf",
                initialName: "Document.pdf",
                initialSize: 3000,
                initialMetadata: nil
            )
        ]
        let nodesRepository = MockWireDriveNodesRepositoryProtocol()
        nodesRepository.getNodes_MockValue = (nodes: [], nextOffset: nil)
        nodesRepository.getNodeId_MockMethod = { _ in nil }

        let nodeCache = MockWireDriveNodeCacheProtocol()
        nodeCache.itemFor_MockMethod = { _ in nil }
        nodeCache.setItemFor_MockMethod = { _, _ in }

        let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = AnyPublisher(Just(nil))

        let fileCache = MockFileCache()
        fileCache.fileURLForKey_MockMethod = { _ in nil }

        return WireDriveAttachmentsPreviewViewModel(
            attachments: attachments,
            alignment: .leading,
            fetchNodeUseCase: WireDriveFetchNodeUseCase(
                repository: nodesRepository,
                cache: nodeCache
            ),
            getAssetUseCase: WireDriveGetAssetUseCase(
                localAssetRepository: localAssetRepository,
                fileCache: fileCache
            ),
            nodeCache: nodeCache,
            localAssetRepository: localAssetRepository,
            lastOpenRequest: WireDriveLastOpenRequest(),
            nodeRenameNotifier: WireDriveNodeRenameNotifier()
        )
    }

}
