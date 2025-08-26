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

final class FilesViewTests: XCTestCase {

    private let modifiedAt = try! Date("2023-10-01T12:00:00Z", strategy: .iso8601)
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testFilesViewItemView_withShortStrings() {
        let item = FilesViewItem(
            id: UUID(),
            filename: "image.jpg",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesViewItemView_withLongStrings() {
        let item = FilesViewItem(
            id: UUID(),
            filename: "some random file with a long name.excel",
            ownedBy: "Liana Margaret Smith-Jones",
            modifiedAt: modifiedAt,
            icon: .spreadsheet
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesViewItemView_dynamicTypeVariants() {
        let item = FilesViewItem(
            id: UUID(),
            filename: "some random file with a long name.excel",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .spreadsheet
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        for dynamicTypeSize in [DynamicTypeSize.allCases.min()!, DynamicTypeSize.allCases.max()!] {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testFilesViewItemView_whenDownloading() {
        let item = FilesViewItem(
            id: UUID(),
            filename: "image.jpg",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image
        )
        let asset = WireCellsLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .downloading(progress: 50)
        )

        let view = FilesViewItemView(viewModel: .make(item: item, asset: asset))
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesViewItemView_whenDownloadFailed() {
        let item = FilesViewItem(
            id: UUID(),
            filename: "image.jpg",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image
        )
        let asset = WireCellsLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .failed(error: URLError(.notConnectedToInternet))
        )

        let view = FilesViewItemView(viewModel: .make(item: item, asset: asset))
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }
}

// MARK: - Private Helpers

private extension FilesItemViewModel {

    static func make(
        item: FilesViewItem,
        asset: WireCellsLocalAsset? = nil
    ) -> FilesItemViewModel {
        let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = CurrentValueSubject<WireCellsLocalAsset?, Never>(asset)
            .eraseToAnyPublisher()

        return FilesItemViewModel(
            item: item,
            localAssetRepository: localAssetRepository,
            locale: Locale(identifier: "en_US_POSIX"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: .gmt
        )
    }

}
