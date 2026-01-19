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

final class WireCellsRestoreNodeUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
    private let nodeCache = MockWireCellsNodeCacheProtocol()
    private let sut: WireCellsRestoreNodeVersionUseCase

    init() {
        self.sut = WireCellsRestoreNodeVersionUseCase(
            repository: repository,
            localAssetsRepository: localAssetRepository,
            nodeCache: nodeCache
        )
    }

    func `It invokes methods to restore version and updates asset locally`() async throws {
        // given
        nodeCache.setItemFor_MockMethod = { _, _ in }
        repository.restoreVersionNodeIDVersionID_MockMethod = { _, _ in () }
        localAssetRepository.refreshAssetMetadataNodeID_MockValue = (
            WireCellsNode.fixture(),
            WireCellsLocalAsset.fixture()
        )

        // when
        try await sut.invoke(nodeID: .mockID1, versionID: .mockID10)

        // then
        #expect(nodeCache.setItemFor_Invocations.count == 1)
        #expect(repository.restoreVersionNodeIDVersionID_Invocations.count == 1)
        #expect(localAssetRepository.refreshAssetMetadataNodeID_Invocations.count == 1)
    }

    func `It fails restoring a version`() async throws {
        // given
        repository.restoreVersionNodeIDVersionID_MockError = NSError(domain: "any", code: 0)

        // when
        await #expect(throws: WireCellsRestoreNodeVersionUseCase.Failure.unableToRestoreNodeVersion) {
            // then
            try await sut.invoke(nodeID: .mockID1, versionID: .mockID10)
        }
    }

}
