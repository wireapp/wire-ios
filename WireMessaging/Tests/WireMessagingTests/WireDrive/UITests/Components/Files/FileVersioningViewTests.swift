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
    private var repository: MockWireDriveNodesRepositoryProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesAPI = MockNodesAPIProtocol()
        repository = MockWireDriveNodesRepositoryProtocol()
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesAPI = nil
        repository = nil
    }

    // TODO: [WPB-21903] - fix snapshot test currently failing on the CI
//    @MainActor
//    func testFileVersioningSuccess() async {
//        let viewModel = await makeViewModel(testCase: .success)
//        let view = FileVersioningView(viewModel: viewModel)
//            .frame(width: 375, height: 667)
//
//        snapshotHelper
//            .withUserInterfaceStyle(.light)
//            .verify(matching: view, named: "light")
//        snapshotHelper
//            .withUserInterfaceStyle(.dark)
//            .verify(matching: view, named: "dark")
//    }

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

        let fetchNodeVersionUseCase = WireDriveFetchNodeVersionsUseCase(
            repository: repository
        )

        let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()

        let restoreNodeVersionUseCase = WireDriveRestoreNodeVersionUseCase(
            repository: repository,
            localAssetsRepository: localAssetRepository,
            nodeCache: MockWireDriveNodeCacheProtocol()
        )

        let getAssetUseCase = WireDriveGetAssetUseCase(
            localAssetRepository: localAssetRepository,
            fileCache: MockFileCache()
        )

        let viewModel = FileVersioningViewModel(
            nodeID: .mockID1,
            name: "foo.jpg",
            eTag: nil,
            context: (Locale(identifier: "en_US_POSIX"), Calendar(identifier: .gregorian), TimeZone.gmt),
            fetchNodeVersionsUseCase: fetchNodeVersionUseCase,
            restoreNodeVersionUseCase: restoreNodeVersionUseCase,
            getAssetUseCase: getAssetUseCase,
            accentColorProvider: { .default }
        )

        switch testCase {
        case .success:
            repository.getVersionsNodeID_MockValue = WireDriveNodeVersion.mock
            await viewModel.fetch()
        case .restore:
            viewModel.state = .restoringVersion
        }

        return viewModel
    }

}
