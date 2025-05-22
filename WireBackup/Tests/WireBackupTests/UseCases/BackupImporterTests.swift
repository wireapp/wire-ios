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
import KaliumBackup
import Testing
import WireFoundation

@testable import WireBackup

struct BackupImporterTests {

    private let password = "Cp2mXgrj.3-qX92p3BRG"

    @Test(arguments: [
        "android-encrypted",
        "android-unencrypted",
        "ios-encrypted",
        "ios-unencrypted",
        "web-encrypted",
        "web-unencrypted"
    ])
    func testPeekingIntoBackupFilesFromAllPlatforms(resource: String) async throws {

        let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        defer { try? FileManager.default.removeItem(at: workDirectoryURL) }

        let importer = BackupImporter(
            selfUserID: QualifiedID(
                id: UUID(uuidString: "cfc7f55a-2ccf-4557-b212-32b2c89bf1a2")!,
                domain: "staging.zinfra.io"
            ),
            workDirectoryURL: workDirectoryURL,
            fileUnarchiver: ZIPFoundationFileUnarchiver()
        )

        let backupURL = try #require(Bundle.module.url(forResource: resource, withExtension: "wbu"))
        let result = try await importer.peek(into: backupURL)

        #expect(result.isEncrypted == resource.hasSuffix("-encrypted"))
        #expect(result.version == "4")

    }

    // TODO: [WPB-16658] add more tests

}
