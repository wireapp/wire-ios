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

import Testing
import WireMessagingDomainSupport

@testable import WireMessagingDomain

@MainActor
final class WireDriveEmptyRecycleBinUseCaseTests {

    private let repository = MockWireDriveNodesRepositoryProtocol()
    private let sut: WireDriveEmptyRecycleBinUseCase

    init() {
        self.sut = WireDriveEmptyRecycleBinUseCase(
            repository: repository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireDriveLocalAssetStoreProtocol()
        )
    }

    @Test
    func invoke_PermanentlyDeletesCellRecycleBin() async throws {
        repository.deleteNodesLocatorsPermanently_MockMethod = { locators, permanently in
            #expect(locators == [.path("conversation/recycle_bin")])
            #expect(permanently)
            return true
        }

        try await sut.invoke(cellName: "conversation")

        #expect(repository.deleteNodesLocatorsPermanently_Invocations.count == 1)
    }

    @Test
    func invoke_ServerRejectsDeletion() async {
        repository.deleteNodesLocatorsPermanently_MockValue = false

        await #expect(throws: WireDriveEmptyRecycleBinError.self) {
            try await sut.invoke(cellName: "conversation")
        }
    }

    @Test
    func invoke_PropagatesRepositoryError() async {
        enum RepositoryError: Error { case unavailable }
        repository.deleteNodesLocatorsPermanently_MockError = RepositoryError.unavailable

        await #expect(throws: RepositoryError.unavailable) {
            try await sut.invoke(cellName: "conversation")
        }
    }
}
