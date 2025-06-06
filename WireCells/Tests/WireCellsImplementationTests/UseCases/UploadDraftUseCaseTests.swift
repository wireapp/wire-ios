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
import UniformTypeIdentifiers
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

final class UploadDraftUseCaseTests {

    private let fileURL = URL.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
    private let draftsRepository = DraftsRepositoryProtocolMock()
    private lazy var sut = UploadDraftUseCase(cellName: "cell-name", draftRepository: draftsRepository)

    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test
    func invokeWithMissingFileURL() async {
        // Given
        let url = URL.temporaryDirectory.appendingPathComponent("some-missing-file.txt")

        // When, Then
        let sut = sut
        await #expect(throws: (any Error).self) {
            try await sut.invoke(fileURL: url)
        }
    }

    @Test
    func invokeWithWithFileURL() async throws {
        // Given
        let fileContent = "This is a test file content."
        let data = Data(fileContent.utf8)
        try data.write(to: fileURL)

        // When
        try await sut.invoke(fileURL: fileURL)

        // Then
        let receivedArgs = await draftsRepository
            .addAssetURLURLAssetSizeIntCellNameStringFileNameStringFileTypeUTTypeVoidReceivedArguments
        #expect(receivedArgs?.assetURL == fileURL)
        #expect(receivedArgs?.assetSize == data.count)
        #expect(receivedArgs?.cellName == "cell-name")
        #expect(receivedArgs?.fileName == fileURL.lastPathComponent)
        #expect(receivedArgs?.fileType == UTType.plainText)
    }
}
