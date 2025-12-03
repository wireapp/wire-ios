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
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FileVersioningViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var nodesAPI: MockNodesAPIProtocol!
    private var repository: MockWireCellsNodesRepositoryProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesAPI = MockNodesAPIProtocol()
        repository = MockWireCellsNodesRepositoryProtocol()
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesAPI = nil
        repository = nil
    }

    @MainActor
    func testFileVersioningSuccess() async {
        let viewModel = await makeViewModel(testCase: .success)
        let view = FileVersioningView(viewModel: viewModel)
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFileVersioningRestoringVersion() async {
        let viewModel = await makeViewModel(testCase: .restore)
        let view = FileVersioningView(viewModel: viewModel)
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    enum TestCase {
        case success
        case restore
    }

    @MainActor
    private func makeViewModel(
        testCase: TestCase
    ) async -> FileVersioningViewModel {

        let fetchNodeVersionUseCase = WireCellsFetchNodeVersionsUseCase(
            repository: repository
        )

        let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()

        localAssetRepository.observeAssetNodeID_MockValue = Just(nil).eraseToAnyPublisher()

        let getAssetUseCase = WireCellsGetAssetUseCase(
            localAssetRepository: localAssetRepository,
            fileCache: MockFileCache()
        )

        let restoreNodeVersionUseCase = WireCellsRestoreNodeVersionUseCase(
            repository: repository,
            localAssetsRepository: localAssetRepository,
            nodeCache: MockWireCellsNodeCacheProtocol()
        )

        let viewModel = FileVersioningViewModel(
            nodeID: .mockID1,
            name: "foo.jpg",
            fetchNodeVersionsUseCase: fetchNodeVersionUseCase,
            getAssetUseCase: getAssetUseCase,
            restoreNodeVersionUseCase: restoreNodeVersionUseCase,
            localAssetRepository: localAssetRepository,
            accentColorProvider: { .default }
        )

        switch testCase {
        case .success:
            var mock = WireCellsNodeVersion.mock
            mock.removeFirst() // this is set to current Date and will fail the snapshot tests
            repository.getVersionsNodeID_MockValue = mock
            await viewModel.fetch()
        case .restore:
            viewModel.state = .restoringVersion
        }

        return viewModel
    }

}
