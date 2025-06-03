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

import Foundation
import Testing
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

final class PublishDraftsUseCaseTests {

    private let nodesAPI = NodesAPIProtocolMock()
    private lazy var uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
    private lazy var draftsRepository = DraftsRepository(
        uploadManager: uploadManager,
        nodesAPI: nodesAPI,
        drafts: [
            "cell-1": [
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .cancelled),
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-2": [
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .failed(error: .fileNotFound)),
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-3": [
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .uploading(progress: 0.5)),
                WireCellsNodeID.fixture(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ]
        ]
    )
    private lazy var sut = PublishDraftsUseCase(cellName: "cell-name", draftRepository: draftsRepository)

    @Test(arguments: ["cell-1", "cell-2", "cell-3"])
    func invoke_whenNotAllFilesUploaded(cellName: String) async throws {
        // Given
        let sut = PublishDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)

        // When, Then
        await #expect(throws: (any Error).self) {
            try await sut.invoke()
        }
    }

}
