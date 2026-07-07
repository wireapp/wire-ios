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
        UserDefaults.standard.set(true, forKey: "enableDrivePermissions")
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
        #expect(sut.menuActions == [.primaryAction, .makeAvailableOffline])
    }

    private func makeSut(isReadOnly: Bool) -> FilesItemViewModel {
        FilesItemViewModel(
            item: .fixture(isReadOnly: isReadOnly),
            selectedSortingKey: .date,
            conversationName: "Hello",
            localAssetRepository: localAssetRepository,
            onItemAction: { _, _ in },
            locale: Locale(identifier: "en_US_POSIX"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: .gmt,
            isBrowsing: false,
            isInRecycleBin: false
        )
    }
}
