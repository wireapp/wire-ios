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
import WireDomainPkg
import WireDomainPkgSupport
import WireFoundationSupport
import Testing

@testable import WireDomainPkg

struct ExportBackupFileZipper2FileZipperAdapterTests {

    @Test func testFileArchiverInvocation() async throws {
        // Given
        let mockFileArchiver = ExportBackupFileArchiverProtocolMock()
        mockFileArchiver.zipResourcesAtResourceURLsURLIntoDestinationURLURLVoidClosure = { _, _ in }

        let mockDateProvider = MockCurrentDateProviding()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-02T14:42:12+02:00")

        let sut = ExportBackupFileZipper2FileZipperAdapter(
            fileManager: .default,
            fileArchiver: mockFileArchiver,
            currentDateProvider: mockDateProvider
        )

        // When
        let destination = try sut.zip(
            entries: [
                URL(filePath: "/a/b/c", directoryHint: .notDirectory).path(),
                URL(filePath: "/e/f/g", directoryHint: .notDirectory).path(),
                URL(filePath: "/i/j/k", directoryHint: .notDirectory).path()
            ]
        )
        let destinationURL = URL(filePath: destination, directoryHint: .notDirectory)

        // Then
        #expect(mockFileArchiver.zipResourcesAtResourceURLsURLIntoDestinationURLURLVoidReceivedInvocations.count == 1)
        let invocation = try #require(mockFileArchiver.zipResourcesAtResourceURLsURLIntoDestinationURLURLVoidReceivedInvocations.first)
        #expect(invocation.resourceURLs.map { $0.path() } == ["/a/b/c", "/e/f/g", "/i/j/k"])
        #expect(destinationURL.lastPathComponent == "2025-04-02T12:42:12Z_backup.zip")
        #expect(destinationURL.deletingLastPathComponent().lastPathComponent == "destination")
    }

}
