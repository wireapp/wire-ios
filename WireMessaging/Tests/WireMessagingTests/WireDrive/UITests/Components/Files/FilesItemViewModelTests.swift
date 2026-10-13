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
import Testing
import WireMessagingDomain

@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class FilesItemViewModelTests {
    private let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()
    private let localAssetStore = MockWireDriveLocalAssetStoreProtocol()
    private let fileCache = MockFileCache()

    init() async {
        localAssetRepository.observeAssetNodeID_MockValue = Just(WireDriveLocalAsset.fixture()).eraseToAnyPublisher()
        localAssetRepository.assetNodeID_MockValue = .fixture()
    }

    @Test
    func hasEditorMenuActions() async throws {
        let sut = makeSut(isReadOnly: false)

        #expect(
            sut.menuActions == [
                .editTags,
                .rename,
                .moveToFolder,
                .primaryAction,
                .makeAvailableOffline,
                .shareLink,
                .deleteToRecycleBin
            ]
        )
    }

    @Test
    func hasViewerMenuActions() async throws {
        let sut = makeSut(isReadOnly: true)
        #expect(sut.menuActions == [.primaryAction])
    }

    // MARK: - Subtitle refresh

    private static let now = Date(timeIntervalSince1970: 1_697_025_600) // 2023-10-11T12:00:00Z
    private static let calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    @Test(arguments: [
        (age: 10.0, expected: 50.0), // "Just now" turns into a relative text after a minute
        (age: 60.0, expected: 60.0),
        (age: 90.0, expected: 30.0), // relative text changes on each full minute
        (age: 3590.0, expected: 10.0), // switches to a clock time after an hour
        (age: 7200.0, expected: 43_200.0) // changes when the day ends (12:00 → 00:00)
    ])
    func delayUntilFormattedDateChanges(age: TimeInterval, expected: TimeInterval) {
        let delay = FilesItemViewModel.delayUntilFormattedDateChanges(
            modifiedAt: Self.now.addingTimeInterval(-age),
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(delay == expected)
    }

    @Test
    func delayUntilFormattedDateChanges_isNilWithoutModificationDate() {
        let delay = FilesItemViewModel.delayUntilFormattedDateChanges(
            modifiedAt: nil,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(delay == nil)
    }

    private func makeSut(isReadOnly: Bool) -> FilesItemViewModel {
        FilesItemViewModel(
            item: .fixture(isReadOnly: isReadOnly),
            selectedSortingKey: .date,
            conversationName: "Hello",
            observeAssetUseCase: WireDriveObserveAssetUseCase(localAssetRepository: localAssetRepository),
            getAssetUseCase: WireDriveGetAssetUseCase(localAssetRepository: localAssetRepository, fileCache: fileCache),
            onItemAction: { _, _ in },
            isBrowsing: false,
            isInRecycleBin: false
        )
    }
}
