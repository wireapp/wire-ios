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
final class WireCellsCreateUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let sut: WireCellsCreateUseCase

    init() {
        self.sut = WireCellsCreateUseCase(
            nodesRepository: repository
        )
    }

    @Test
    func invoke_FolderSuccess() async throws {
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.createFolderAt_MockMethod = { targetPath in
            #expect(targetPath == "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2/Folder-3")
            return WireCellsNode.fixture()
        }

        // When
        _ = try await sut.invoke(
            creationTarget: .folder,
            path: folderPath,
            name: folderName
        )

        // Then
        #expect(repository.preCheckNodePathFindAvailablePath_Invocations.count == 1)
        #expect(repository.createFolderAt_Invocations.count == 1)
    }

    @Test
    func invoke_FileSuccess() async throws {
        let filepath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let filename = "test"
        let template = WireCellsTemplate(
            kind: .document,
            editable: true,
            label: "Microsoft Word",
            UUID: "01-Microsoft Word.docx"
        )

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.createFileAtTemplateUuid_MockMethod = { targetPath, templateId in
            #expect(targetPath == "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2/test.docx")
            #expect(templateId == "01-Microsoft Word.docx")
            return WireCellsNode.fixture()
        }

        // When
        _ = try await sut.invoke(
            creationTarget: .file(template),
            path: filepath,
            name: filename
        )

        // Then
        #expect(repository.preCheckNodePathFindAvailablePath_Invocations.count == 1)
        #expect(repository.createFileAtTemplateUuid_Invocations.count == 1)
    }

    @Test
    func invoke_FailureAlreadyExists() async throws {
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .fileExists(nextPath: "")

        // Then
        await #expect(throws: WireCellsCreateUseCaseError.alreadyExists) {
            // When
            _ = try await sut.invoke(
                creationTarget: .folder,
                path: folderPath,
                name: folderName
            )
        }
    }

    @Test
    func invoke_FailureServerFailedToCreate() async throws {
        // Given
        let folderPath = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2"
        let folderName = "Folder-3"

        // Mock
        repository.preCheckNodePathFindAvailablePath_MockValue = .success
        repository.createFolderAt_MockError = NSError(domain: "Server error", code: 0)

        // Then
        await #expect(throws: WireCellsCreateUseCaseError.serverFailedToCreate) {
            // When
            _ = try await sut.invoke(
                creationTarget: .folder,
                path: folderPath,
                name: folderName
            )
        }
    }

}
