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
import SwiftUI
import UniformTypeIdentifiers
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

// MARK: - View models

extension FilesViewModel {

    /// A stubbed instance of `FilesViewModel` for SwiftUI previews.
    static func preview() -> FilesViewModel {
        FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("root")),
                repository: previewNodesRepository()
            ),
            isCellsStatePending: false,
            localAssetRepository: PreviewLocalAssetRepository(), fileCache: MockFileCache()
        )
    }

}

extension FilesItemViewModel {

    /// A stubbed instance of `FilesItemViewModel` for SwiftUI previews.
    static func preview() -> FilesItemViewModel {
        FilesItemViewModel(
            item: FilesViewItem(
                id: UUID(),
                filename: "foo.jpg",
                ownedBy: "Viola",
                modifiedAt: Date(),
                icon: .image
            ),
            localAssetRepository: PreviewLocalAssetRepository(),
            onOpen: { _ in },
        )
    }

}

// MARK: - Dependencies

private func previewNodesRepository() -> any WireCellsNodesRepositoryProtocol {
    let repository = MockWireCellsNodesRepositoryProtocol()
    repository.getNodes_MockMethod = { request in
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay

        if request.offset >= 120 {
            throw URLError(.notConnectedToInternet)
        }

        let nodes = (request.offset ..< request.offset + 30).map { index in
            WireCellsNode(
                uuid: UUID(),
                path: "root/foo-\(index).jpg",
                modified: Date(),
                mimeType: "image/jpeg",
                ownerUserName: "Person \(index)",
            )
        }
        let nextOffset = request.offset + 30
        return (nodes, nextOffset)
    }
    return repository
}

private final class PreviewLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol {

    var failIndex = 0
    var publishers: [UUID: CurrentValueSubject<WireCellsLocalAsset?, Never>] = [:]

    func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        publishers[nodeID]?.value
    }

    func refreshMetadata(nodeID: UUID) async throws {}

    func downloadAsset(nodeID: UUID) async throws {
        failIndex += 1
        // Fail every 3rd download
        let shouldFail = failIndex % 3 == 0

        for progress in stride(from: 0.0, to: 1.1, by: 0.1) {
            let downloadState: WireCellsLocalAsset.DownloadState = if shouldFail, progress > 0.1 {
                .failed(error: URLError(.notConnectedToInternet))
            } else if progress < 1 {
                .downloading(progress: Double(progress))
            } else {
                .downloaded(cacheKey: "cacheKey")
            }

            try await Task.sleep(nanoseconds: 200_000_000)
            let update = WireCellsLocalAsset(
                nodeID: nodeID,
                eTag: "something",
                path: "some/path.jpg",
                contentType: nil,
                size: nil,
                downloadState: downloadState
            )

            publishers[nodeID]?.send(update)

            if shouldFail, progress > 0.1 {
                break
            }
        }
    }

    func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireCellsLocalAsset?, Never> {
        let publisher = publishers[nodeID] ?? CurrentValueSubject<WireCellsLocalAsset?, Never>(nil)
        publishers[nodeID] = publisher
        return publisher.eraseToAnyPublisher()
    }

    func cancelDownload(nodeID: UUID) {}

}
