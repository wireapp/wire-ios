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
final class WireCellsCreateFolderUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let sut: WireCellsCreateFolderUseCase

    init() {
        self.sut = WireCellsCreateFolderUseCase(
            nodesRepository: repository
        )

    }

    @Test
    func invoke_Success() async throws {
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.createFolderAt_MockMethod = { targetPath in
            #expect(targetPath == "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2/Folder-3")
        }

        // When
        try await sut.invoke(
            folderPath: folderPath,
            folderName: folderName
        )

        // Then
        #expect(repository.preCheckNodePathFindAvailablePath_Invocations.count == 1)
        #expect(repository.createFolderAt_Invocations.count == 1)
    }

    @Test
    func invoke_FailureFolderAlreadyExists() async throws {
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .fileExists(nextPath: "")

        // Then
        await #expect(throws: WireCellsCreateFolderUseCaseError.folderAlreadyExists) {
            // When
            try await sut.invoke(
                folderPath: folderPath,
                folderName: folderName
            )
        }
    }

    @Test
    func invoke_FailureServerFailedToCreateFolder() async throws {
        // Given
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.createFolderAt_MockError = NSError(domain: "Server error", code: 0)

        // Then
        await #expect(throws: WireCellsCreateFolderUseCaseError.serverFailedToCreateFolder) {
            // When
            try await sut.invoke(
                folderPath: folderPath,
                folderName: folderName
            )
        }
    }

}
