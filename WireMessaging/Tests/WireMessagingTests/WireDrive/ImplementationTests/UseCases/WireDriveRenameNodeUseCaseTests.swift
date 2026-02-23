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

import Foundation
import Testing

import WireMessagingDomainSupport
@testable import WireMessagingDomain

@MainActor
final class WireDriveRenameNodeUseCaseTests {

    private let repository = MockWireDriveNodesRepositoryProtocol()
    private let cache = MockWireDriveNodeCacheProtocol()
    private let localAssetsRepository = MockWireDriveLocalAssetRepositoryProtocol()
    private let nodeCache = MockWireDriveNodeCacheProtocol()
    private let nodeRenameNotifier = WireDriveNodeRenameNotifier()
    private let sut: WireDriveRenameNodeUseCase

    init() {
        self.sut = WireDriveRenameNodeUseCase(
            nodesRepository: repository,
            localAssetsRepository: localAssetsRepository,
            nodeCache: nodeCache,
            nodeRenameNotifier: nodeRenameNotifier
        )
    }

    @Test
    func invoke_Success() async throws {
        // Given
        let nodeID = UUID()
        let nodeFilepath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.png"
        let newFilename = "foo1"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.renameNodeNodeIDTargetPath_MockValue = true
        localAssetsRepository.refreshAssetMetadataNodeID_MockValue = (
            WireDriveNode.fixture(uuid: nodeID),
            WireDriveLocalAsset.fixture(nodeID: nodeID)
        )
        nodeCache.setItemFor_MockMethod = { _, _ in }

        // When
        try await sut.invoke(
            nodeID: nodeID,
            nodeFilepath: nodeFilepath,
            newFilename: newFilename,
            isFolder: false
        )

        // Then
        #expect(repository.preCheckNodePathFindAvailablePath_Invocations.count == 1)
        #expect(repository.renameNodeNodeIDTargetPath_Invocations.count == 1)
        #expect(localAssetsRepository.refreshAssetMetadataNodeID_Invocations.count == 1)
        #expect(nodeCache.setItemFor_Invocations.count == 1)
    }

    @Test
    func invoke_FailureFileAlreadyExists() async throws {
        // Given
        let nodeID = UUID()
        let nodeFilepath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Imagefoo.png"
        let newFilename = "foo1"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .fileExists(nextPath: "")
        repository.renameNodeNodeIDTargetPath_MockValue = true
        localAssetsRepository.refreshAssetMetadataNodeID_MockValue = (
            WireDriveNode.fixture(),
            WireDriveLocalAsset.fixture()
        )
        nodeCache.setItemFor_MockMethod = { _, _ in }

        // Then
        await #expect(throws: WireDriveRenameNodeError.fileAlreadyExists) {
            // When
            try await sut.invoke(
                nodeID: nodeID,
                nodeFilepath: nodeFilepath,
                newFilename: newFilename,
                isFolder: false
            )
        }
    }

    @Test
    func invoke_FailureInvalidPath() async throws {
        // Given
        let nodeID = UUID()
        let nodeFilepath = ""
        let newFilename = "foo1"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.renameNodeNodeIDTargetPath_MockValue = true
        localAssetsRepository.refreshAssetMetadataNodeID_MockValue = (
            WireDriveNode.fixture(),
            WireDriveLocalAsset.fixture()
        )
        nodeCache.setItemFor_MockMethod = { _, _ in }

        // Then
        await #expect(throws: WireDriveRenameNodeError.invalidPath) {
            // When
            try await sut.invoke(
                nodeID: nodeID,
                nodeFilepath: nodeFilepath,
                newFilename: newFilename,
                isFolder: false
            )
        }
    }

    @Test
    func invoke_FailureServerFailedToRename() async throws {
        // Given
        let nodeID = UUID()
        let nodeFilepath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.png"
        let newFilename = "foo1"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.renameNodeNodeIDTargetPath_MockValue = false
        localAssetsRepository.refreshAssetMetadataNodeID_MockValue = (
            WireDriveNode.fixture(),
            WireDriveLocalAsset.fixture()
        )
        nodeCache.setItemFor_MockMethod = { _, _ in }

        // Then
        await #expect(throws: WireDriveRenameNodeError.serverFailedToRenameNode) {
            // When
            try await sut.invoke(
                nodeID: nodeID,
                nodeFilepath: nodeFilepath,
                newFilename: newFilename,
                isFolder: false
            )
        }
    }

}
