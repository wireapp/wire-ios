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

import WireBackup
import WireDomainPkgSupport
import Testing

@testable import WireDomainPkg

struct ExportBackupFileZipper2FileZipperAdapterTests {

    @Test func todo() async throws {
        // Given
        let mockFileArchiver = MockExportBackupFileArchiverProtocol()
        mockFileArchiver.zipResourcesAtTo_MockMethod = { resources, destination in }
        let sut = ExportBackupFileZipper2FileZipperAdapter(
            fileManager: .default,
            fileArchiver: mockFileArchiver
        )

        // When
        let destination = try sut.zip(
            entries: [
                URL(filePath: "/a/b/c", directoryHint: .notDirectory).path(),
                URL(filePath: "/e/f/g", directoryHint: .notDirectory).path(),
                URL(filePath: "/i/j/k", directoryHint: .notDirectory).path()
            ]
        )

        // Then
        print(destination)
    }

}

/*
private final class MockExportBackupFileArchiver: ExportBackupFileArchiverProtocol {

//    func zip(entries: [String]) throws -> String {
//        entries.joined(separator: "\n")
//    }

    func zipResources(at resourceURLs: URL, to destinationURL: URL) throws {
        fatalError()
    }

}
*/
